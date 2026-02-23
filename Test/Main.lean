/-
Copyright (c) 2025 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Emilio J. Gallego Arias
-/

import Test.Core
import Test.Transport

def main : IO Unit := do
  Dap.Tests.runCoreTests
  Dap.Tests.runTransportTests
  IO.println "All tests passed."
