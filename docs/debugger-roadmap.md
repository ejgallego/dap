# Debugger Roadmap

This file tracks active debugger work and near-term milestones.

Stable architecture guardrails and review policy live in:
- `ImpLab/Debugger/AGENTS.md`

## Active priorities

1. Remove remaining duplicated behavior between `ImpLab/Debugger/Widget/Server.lean` and `ImpLab/Debugger/DAP/Stdio.lean` by lifting semantics to `ImpLab/Debugger/Core.lean`.
2. Keep line/function source mapping explicit and centralized so stack and breakpoint rendering stay consistent.
3. Preserve strict DAP lifecycle ordering and stable payload shapes for editor compatibility.
4. Keep docs/examples aligned with `ProgramInfo`-only launch/export flows and thin `app/` entrypoints.

## Open work queue

- Audit both transports for duplicate request validation and decode helpers.
- Add/adjust transport tests for lifecycle edge cases (invalid ordering, repeated terminate/disconnect).
- Verify breakpoint and stack location mapping in multi-function traces.
- Keep `client/README.md`, `docs/debugger.md`, and `README.md` aligned with current launch contract.
- Keep executable roots (`app/ToyDap.lean`, `app/ExportMain.lean`) as thin wrappers.

## Milestones

1. Transport parity audit complete (no semantic drift from core).
2. Source-mapping checks expanded for multi-frame scenarios.
3. Lifecycle sanity suite covers error-ordering paths.
4. Docs are trimmed to non-overlapping scopes (`README.md`, `docs/debugger.md`, `ImpLab/Debugger/AGENTS.md`, and this roadmap).
