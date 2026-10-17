# IronSoulKaitun V4 Standalone

This folder is the clean V4-only implementation area.

## Rules
- Do not load any V2 bootstrap or V2 system files.
- Do not use `main` as a fallback source for runtime modules.
- Keep every V4 module and patch under this branch and this folder.
- Fail with a visible diagnostic if a required module is missing.
- Gameplay modules must be rewritten or explicitly reviewed before being connected to the bootstrap.

## Current status
- Standalone loader: created.
- Standalone bootstrap: created.
- Standalone configuration: created.
- Standalone diagnostics: created.
- Dungeon, lobby, transition, auto-skill, and level-stop runtime modules: not yet implemented in this clean structure.
