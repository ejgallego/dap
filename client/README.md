# Lean Toy DAP Client (VS Code)

This extension bridges VS Code's Debug Adapter Protocol (DAP) to Lean RPC methods implemented in this repository (`Dap.Server.*`).

## Prerequisites

- `leanprover.lean4` VS Code extension installed and active.
- A Lean file in this project open in VS Code.
- The file should import `Dap` (or `Dap.Server`) so RPC methods are registered in the server environment.

## Build and sideload

```bash
cd client
npm install
npm run compile
```

Then package/sideload as you usually do (e.g. `vsce package` and install VSIX).

## Launch configuration

Use debug type `lean-toy-dap`.

`source`:
- Absolute path to a Lean file (used as RPC context position).

Program input:
- Either `program` (inline JSON array), or
- `programFile` (path to JSON file containing that array).

Example:

```json
{
  "name": "Lean Toy DAP",
  "type": "lean-toy-dap",
  "request": "launch",
  "source": "${file}",
  "programFile": "${workspaceFolder}/program.json",
  "stopOnEntry": true
}
```

A ready-to-run sample is included at `client/program.sample.json`.

## Program JSON format

Each statement is:
- `{"dest":"x","rhs":{"const":{"value":6}}}` or
- `{"dest":"z","rhs":{"bin":{"op":"add","lhs":"x","rhs":"y"}}}`

Operator values: `add`, `sub`, `mul`, `div`.

## Supported DAP requests

- `initialize`
- `launch`
- `setBreakpoints`
- `configurationDone`
- `threads`
- `stackTrace`
- `scopes`
- `variables`
- `next`
- `stepBack`
- `continue`
- `pause`
- `disconnect`

## Notes

- Breakpoints are interpreted as statement lines in the toy program (1-based).
- Variables scope is currently a single `locals` scope.
