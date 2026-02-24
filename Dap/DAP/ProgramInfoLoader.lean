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

private def initProjectSearchPath : IO Unit := do
  let sysroot ← Lean.findSysroot
  Lean.initSearchPath sysroot [System.FilePath.mk ".lake/build/lib/lean"]

private def parseNameOrThrow (kind raw : String) : IO Name := do
  match Dap.parseName? raw with
  | some n =>
    pure n
  | none =>
    throw <| IO.userError s!"Invalid {kind} name '{raw}'"

private unsafe def evalProgramInfo
    (env : Environment) (opts : Options) (decl : Name) : Except String ProgramInfo := do
  match env.evalConstCheck ProgramInfo opts ``Dap.ProgramInfo decl with
  | .ok info =>
    info.validate
  | .error infoErr =>
    throw s!"Declaration '{decl}' is not Dap.ProgramInfo.\nProgramInfo error: {infoErr}"

private def resolveDeclOrThrow
    (env : Environment)
    (rawDecl : String)
    (declName : Name)
    (moduleName? : Option Name)
    (includeExamples : Bool) : IO Name := do
  let candidates := Dap.candidateDeclNames declName moduleName? includeExamples
  match Dap.resolveFirstDecl? env candidates with
  | some n =>
    pure n
  | none =>
    let attempted := Dap.renderCandidateDecls candidates
    throw <| IO.userError s!"Could not resolve declaration '{rawDecl}'. Tried: {attempted}"

def loadProgramInfoFromDecl
    (rawDecl : String)
    (moduleName? : Option Name := some `Main)
    (includeExamples : Bool := true) : IO ProgramInfo := do
  initProjectSearchPath
  let declName ← parseNameOrThrow "declaration" rawDecl
  let env ← Dap.importProjectEnv
  let resolved ← resolveDeclOrThrow env rawDecl declName moduleName? includeExamples
  let opts : Options := {}
  match unsafe evalProgramInfo env opts resolved with
  | .ok info =>
    pure info
  | .error err =>
    throw <| IO.userError err

def loadProgramInfoFromModuleDecl
    (rawModule : String)
    (rawDecl : String := "mainProgram")
    (includeExamples : Bool := false) : IO ProgramInfo := do
  initProjectSearchPath
  let moduleName ← parseNameOrThrow "module" rawModule
  let declName ← parseNameOrThrow "declaration" rawDecl
  let env ← Dap.importEnvForModule moduleName
  let resolved ← resolveDeclOrThrow env rawDecl declName (some moduleName) includeExamples
  let opts : Options := {}
  match unsafe evalProgramInfo env opts resolved with
  | .ok info =>
    pure info
  | .error err =>
    throw <| IO.userError err

end Dap
