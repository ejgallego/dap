/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Lean
import Dap.Lang.Ast
import Dap.DAP.Resolve

open Lean

namespace Dap

structure LaunchProgram where
  programInfo : ProgramInfo

def decodeProgramInfoJson (json : Json) : Except String ProgramInfo :=
  match (fromJson? json : Except String ProgramInfo) with
  | .ok programInfo =>
    programInfo.validate
  | .error err =>
    throw s!"Invalid 'programInfo' payload: {err}"

def decodeLaunchProgramJson (json : Json) : Except String LaunchProgram := do
  let programInfo ← decodeProgramInfoJson json
  pure { programInfo }

private unsafe def evalLaunchProgramFromDecl
    (env : Environment) (opts : Options) (decl : Name) : Except String LaunchProgram := do
  match env.evalConstCheck ProgramInfo opts ``Dap.ProgramInfo decl with
  | .ok rawProgramInfo =>
    let programInfo ← rawProgramInfo.validate
    pure { programInfo }
  | .error infoErr =>
    throw s!"Declaration '{decl}' is not Dap.ProgramInfo.\nProgramInfo error: {infoErr}"

def resolveLaunchProgramFromEnv
    (env : Environment)
    (entryPoint : String)
    (moduleName? : Option Name := none)
    (opts : Options := {}) : Except String LaunchProgram := do
  let declName ←
    match Dap.parseDeclName? entryPoint with
    | some n => pure n
    | none => throw s!"Invalid entryPoint '{entryPoint}'"
  let candidates := Dap.candidateDeclNames declName (moduleName? := moduleName?)
  let resolved ←
    match Dap.resolveFirstDecl? env candidates with
    | some n => pure n
    | none =>
      let attempted := Dap.renderCandidateDecls candidates
      throw s!"Could not resolve entryPoint '{entryPoint}'. Tried: {attempted}"
  match unsafe evalLaunchProgramFromDecl env opts resolved with
  | .ok launchProgram => pure launchProgram
  | .error err => throw err

end Dap
