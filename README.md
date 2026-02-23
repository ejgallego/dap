# dap

Lean 4 toy project for:
- an arithmetic function-based interpreter,
- step-by-step execution traces,
- an interactive infoview widget to inspect state and move backward/forward,
- a DAP-style debug service exposed as Lean RPC methods,
- a standalone DAP adapter binary (`toydap`) that speaks DAP over stdio,
- a side-loadable VS Code debug client in `client/`.

## Project layout

- `Dap/Lang/Ast.lean`: core AST (`Program` is a list of functions, entrypoint is `main`).
- `Dap/Lang/Dsl.lean`: DSL syntax/macros (`dap%[...]`) + infotree metadata.
- `Dap/Lang/Eval.lean`: environment, call-stack semantics, small-step transition, and full runner.
- `Dap/Lang/History.lean`: shared cursor/history navigation helpers.
- `Dap/Lang/Trace.lean`: execution trace and navigation API (`Explorer`).
- `examples/Main.lean`: sample program and precomputed widget props.
- `Dap/Debugger/Session.lean`: pure debugger session model (breakpoints, continue, next, stepIn, stepOut, stepBack).
- `Dap/Debugger/Core.lean`: session store + DAP-shaped pure core operations.
- `Dap/DAP/Server.lean`: Lean server RPC endpoints implementing DAP-like operations.
- `Dap/DAP/Stdio.lean`: standalone DAP adapter implementation (native DAP protocol over stdio).
- `Dap/Widget/Types.lean`: pure widget data model + trace-to-widget projection helpers.
- `Dap/Widget/Server.lean`: widget props + `traceExplorerWidget`.
- `Dap/DAP/Export.lean`: `dap-export` declaration loader/export logic.
- `Test/Core.lean`: core/runtime/debugger tests.
- `Test/Transport.lean`: DAP stdio transport lifecycle/framing tests.
- `Test/Main.lean`: test runner executable.
- `client/`: VS Code extension scaffold for side-loading (`lean-toy-dap` debug type).

## Build and run

```bash
lake build
lake exe dap
lake exe toydap
lake exe dap-export --help
lake exe dap-tests
```

## DSL syntax

The toy language has one term elaborator:

- `dap%[...] : Dap.ProgramInfo`

`dap%[...]` accepts only function definitions and must include `main()` as entrypoint.

Statements:

```lean
let v := N
let v := add v1 v2
let v := sub v1 v2
let v := mul v1 v2
let v := div v1 v2
let v := call f(a, b, ...)
return v
```

Example:

```lean
def p : Dap.ProgramInfo := dap%[
  def addMul(x, y) := {
    let s := add x y,
    let z := mul s y,
    return z
  },
  def main() := {
    let a := 2,
    let b := 5,
    let out := call addMul(a, b)
  }
]
```

`ProgramInfo.located` stores source locations with function context (`func`, `stmtLine`, `span`), which powers function-aware breakpoints and stack traces.

## Execution model

The interpreter uses explicit call frames:
- each frame has function name, local environment, and program counter,
- `call` pushes a frame,
- `return` pops and assigns into caller destination,
- stepping (`step`) is the semantic foundation for runtime and debugger behavior.

## Lean RPC debug methods

Registered in `Dap.Server`:

- `Dap.Server.dapInitialize`
- `Dap.Server.dapLaunch`
- `Dap.Server.dapLaunchMain`
- `Dap.Server.dapSetBreakpoints`
- `Dap.Server.dapThreads`
- `Dap.Server.dapStackTrace`
- `Dap.Server.dapScopes`
- `Dap.Server.dapVariables`
- `Dap.Server.dapNext`
- `Dap.Server.dapStepIn`
- `Dap.Server.dapStepOut`
- `Dap.Server.dapStepBack`
- `Dap.Server.dapContinue`
- `Dap.Server.dapPause`
- `Dap.Server.dapDisconnect`

`dapLaunch` accepts only `programInfo`.
`dapLaunchMain` resolves an entry declaration and requires it to be `Dap.ProgramInfo`.

## Widget usage

In a Lean file:

```lean
import examples.Main

#widget Dap.traceExplorerWidget with Dap.Lang.Examples.sampleTraceProps
```

The widget shows current function, pc, call depth, and locals over time-travelled states.

## VS Code side-load client

The `client/` extension launches `toydap`.

See `client/README.md` for build/sideload and launch configuration.
Launch inputs are `entryPoint` (default `mainProgram`) or `programInfo` / `programInfoFile`.

## ProgramInfo export helper

Use `dap-export` to generate source-aware JSON from a Lean declaration:

```bash
lake exe dap-export --decl Dap.Lang.Examples.mainProgram --out .dap/programInfo.generated.json
```

`--decl` must resolve to a `Dap.ProgramInfo` declaration.
