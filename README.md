# dap

Lean 4 toy project for:
- an arithmetic let-normal-form interpreter,
- step-by-step execution traces,
- an interactive infoview widget to inspect state and move backward/forward,
- a DAP-style debug service exposed as Lean RPC methods,
- a side-loadable VS Code debug client in `client/`.

## Project layout

- `Dap/Syntax.lean`: core AST (`Program` is a list of `let` statements).
- `Dap/Eval.lean`: environment, small-step semantics, and full program runner.
- `Dap/Trace.lean`: execution trace and navigation API (`Explorer`).
- `Dap/DebugModel.lean`: pure debugger session model (breakpoints, continue, next, stepBack).
- `Dap/Server.lean`: Lean server RPC endpoints implementing DAP-like operations.
- `Dap/Widget.lean`: widget props + `traceExplorerWidget`.
- `Dap/Examples.lean`: sample program and precomputed widget props.
- `Test/Main.lean`: executable tests.
- `client/`: VS Code extension scaffold for side-loading (`lean-toy-dap` debug type).
- `DAP_PLAN.md`: roadmap to expose this runtime over DAP.

## Build and run

```bash
lake build
lake exe dap
lake exe dap-tests
```

## Lean RPC debug methods

The following RPC methods are registered in `Dap.Server`:

- `Dap.Server.dapInitialize`
- `Dap.Server.dapLaunch`
- `Dap.Server.dapSetBreakpoints`
- `Dap.Server.dapThreads`
- `Dap.Server.dapStackTrace`
- `Dap.Server.dapScopes`
- `Dap.Server.dapVariables`
- `Dap.Server.dapNext`
- `Dap.Server.dapStepBack`
- `Dap.Server.dapContinue`
- `Dap.Server.dapPause`
- `Dap.Server.dapDisconnect`

They are designed to be called over Lean's `$/lean/rpc/call` transport.

## Widget usage

In a Lean file:

```lean
import Dap.Examples

#widget Dap.traceExplorerWidget with Dap.Examples.sampleTraceProps
```

Place the cursor on the `#widget` command in the infoview to interact with:
- `Back` / `Forward` navigation over recorded states,
- highlighted current instruction (`pc`),
- environment bindings at each step.

## VS Code side-load client

The `client/` folder contains an extension that exposes a debug type `lean-toy-dap` and bridges DAP requests to the RPC methods above.

See `client/README.md` for build/sideload steps and launch configuration details.
