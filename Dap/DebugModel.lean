/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Dap.Trace

namespace Dap

inductive StopReason where
  | entry
  | step
  | breakpoint
  | pause
  | terminated
  deriving Repr, BEq, DecidableEq, Inhabited

instance : ToString StopReason where
  toString
    | .entry => "entry"
    | .step => "step"
    | .breakpoint => "breakpoint"
    | .pause => "pause"
    | .terminated => "terminated"

structure DebugSession where
  trace : ExecutionTrace
  cursor : Nat := 0
  breakpoints : Array Nat := #[]
  deriving Repr

namespace DebugSession

def fromTrace (trace : ExecutionTrace) : DebugSession :=
  { trace }

def fromProgram (program : Program) : Except EvalError DebugSession := do
  let trace ← ExecutionTrace.build program
  pure (fromTrace trace)

def maxCursor (session : DebugSession) : Nat :=
  session.trace.states.size - 1

def normalize (session : DebugSession) : DebugSession :=
  { session with cursor := min session.cursor session.maxCursor }

def current? (session : DebugSession) : Option Context :=
  let session := session.normalize
  session.trace.states[session.cursor]?

def currentPc (session : DebugSession) : Nat :=
  (session.current?.map (·.pc)).getD 0

def currentLine (session : DebugSession) : Nat :=
  let psize := session.trace.program.size
  let fallback := max psize 1
  if psize = 0 then
    1
  else
    match session.current? with
    | none => fallback
    | some ctx =>
      if ctx.pc < psize then
        ctx.pc + 1
      else
        psize

def atEnd (session : DebugSession) : Bool :=
  let session := session.normalize
  session.cursor >= session.maxCursor

def isValidBreakpointLine (programSize line : Nat) : Bool :=
  0 < line && line <= programSize

def normalizeBreakpoints (programSize : Nat) (lines : Array Nat) : Array Nat :=
  lines.foldl
    (init := #[])
    (fun acc line =>
      if isValidBreakpointLine programSize line && !acc.contains line then
        acc.push line
      else
        acc)

def setBreakpoints (session : DebugSession) (lines : Array Nat) : DebugSession :=
  { session with breakpoints := normalizeBreakpoints session.trace.program.size lines }

def isBreakpointLine (session : DebugSession) (line : Nat) : Bool :=
  session.breakpoints.contains line

def hitBreakpoint (session : DebugSession) : Bool :=
  session.isBreakpointLine session.currentLine

def bindings (session : DebugSession) : Array (Var × Value) :=
  (session.current?.map Context.bindings).getD #[]

def next (session : DebugSession) : DebugSession × StopReason :=
  let session := session.normalize
  if session.atEnd then
    (session, .terminated)
  else
    let next := { session with cursor := session.cursor + 1 }
    if next.atEnd then
      (next, .terminated)
    else
      (next, .step)

def stepBack (session : DebugSession) : DebugSession × StopReason :=
  let session := session.normalize
  if session.cursor = 0 then
    (session, .pause)
  else
    ({ session with cursor := session.cursor - 1 }, .step)

def continueExecution (session : DebugSession) : DebugSession × StopReason :=
  let session := session.normalize
  if session.atEnd then
    (session, .terminated)
  else
    let fuel := session.maxCursor - session.cursor + 1
    let rec go : Nat → DebugSession → DebugSession × StopReason
      | 0, s =>
        (s, .pause)
      | fuel' + 1, s =>
        let (s, reason) := s.next
        match reason with
        | .terminated =>
          (s, .terminated)
        | _ =>
          if s.hitBreakpoint then
            (s, .breakpoint)
          else
            go fuel' s
    go fuel session

def initialStop (session : DebugSession) (stopOnEntry : Bool) : DebugSession × StopReason :=
  let session := session.normalize
  if stopOnEntry then
    (session, .entry)
  else if session.hitBreakpoint then
    (session, .breakpoint)
  else
    session.continueExecution

end DebugSession

end Dap
