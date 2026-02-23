/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Lean
import Dap.Lang.Trace

open Lean

namespace Dap

structure ProgramLineView where
  functionName : String
  stmtLine : Nat
  sourceLine : Nat
  text : String
  deriving Repr, Inhabited, BEq, Server.RpcEncodable

structure TraceCallFrameView where
  functionName : String
  stmtLine : Nat
  sourceLine : Nat
  deriving Repr, Inhabited, BEq, Server.RpcEncodable

structure BindingView where
  name : String
  value : Int
  deriving Repr, Inhabited, BEq, Server.RpcEncodable

structure StateView where
  functionName : String
  pc : Nat
  stmtLine : Nat
  sourceLine : Nat
  callDepth : Nat
  callStack : Array TraceCallFrameView
  bindings : Array BindingView
  deriving Repr, Inhabited, BEq, Server.RpcEncodable

structure TraceWidgetProps where
  program : Array ProgramLineView
  states : Array StateView
  deriving Repr, Inhabited, BEq, Server.RpcEncodable

def ProgramLineView.ofLocatedStmt (located : LocatedStmt) : ProgramLineView :=
  { functionName := located.func
    stmtLine := located.stmtLine
    sourceLine := located.span.startLine
    text := toString located.stmt }

def BindingView.ofPair (entry : Var × Value) : BindingView :=
  { name := entry.1, value := entry.2 }

private def contextStmtLine (program : Program) (ctx : Context) : Nat :=
  let bodySize := program.bodySizeOf ctx.functionName
  if bodySize = 0 then
    1
  else if ctx.pc < bodySize then
    ctx.pc + 1
  else
    bodySize

private def frameStmtLine (program : Program) (frame : CallFrame) : Nat :=
  let bodySize := program.bodySizeOf frame.func
  if bodySize = 0 then
    1
  else if frame.pc < bodySize then
    frame.pc + 1
  else
    bodySize

def TraceCallFrameView.ofFrame (programInfo : ProgramInfo) (frame : CallFrame) : TraceCallFrameView :=
  let stmtLine := frameStmtLine programInfo.program frame
  let sourceLine := programInfo.locationToSourceLine { func := frame.func, stmtLine }
  { functionName := frame.func
    stmtLine
    sourceLine }

def StateView.ofContext (programInfo : ProgramInfo) (ctx : Context) : StateView :=
  let stmtLine := contextStmtLine programInfo.program ctx
  let sourceLine := programInfo.locationToSourceLine { func := ctx.functionName, stmtLine }
  let callStack := (ctx.frames.reverse.map (TraceCallFrameView.ofFrame programInfo))
  { functionName := ctx.functionName
    pc := ctx.pc
    stmtLine := stmtLine
    sourceLine := sourceLine
    callDepth := ctx.callDepth
    callStack := callStack
    bindings := ctx.bindings.map BindingView.ofPair }

def TraceWidgetProps.ofTrace (programInfo : ProgramInfo) (trace : ExecutionTrace) : TraceWidgetProps :=
  { program := programInfo.located.map ProgramLineView.ofLocatedStmt
    states := trace.states.map (StateView.ofContext programInfo) }

def traceWidgetProps (programInfo : ProgramInfo) : Except EvalError TraceWidgetProps := do
  let trace ← ExecutionTrace.build programInfo.program
  pure (TraceWidgetProps.ofTrace programInfo trace)

end Dap
