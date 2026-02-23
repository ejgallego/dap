/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Dap.Widget.Server
import Dap.Lang.Dsl
import Dap.DAP.Server

namespace Dap.Lang.Examples

open Dap

def mainProgram : ProgramInfo := dap%[
  def bump(x) := {
    let one := 1,
    let out := add x one,
    return out
  },
  def scaleAndShift(x, factor) := {
    let scaled := mul x factor,
    let shift := 2,
    let out := add scaled shift,
    return out
  },
  def main() := {
    let seed := 5,
    let factor := 3,
    let bumped := call bump(seed),
    let out := call scaleAndShift(bumped, factor)
  }
]

#eval run mainProgram

def sampleTraceProps : TraceWidgetProps :=
  match traceWidgetProps mainProgram with
  | .ok props => props
  | .error _ => default

end Dap.Lang.Examples

#widget Dap.traceExplorerWidget with Dap.Lang.Examples.sampleTraceProps
