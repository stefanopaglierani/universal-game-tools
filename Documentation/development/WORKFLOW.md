**English** | [Italiano](WORKFLOW.it.md)

# Development workflow

## Branches

- `main`: stable, reviewed work only.
- Feature branches: `<module>/<short-description>`, e.g. `uptg/milestone-a-minimal-terrain`.
- Documentation-only branches: `docs/<short-description>`.

Merge into `main` through a pull request after the change has been verified in Godot 4.7.2.

## Commits

Short imperative messages, prefixed with the module when relevant:

```
UPTG: add UPTGConfig resource
docs: update testing procedure
```

## Versioning

- Each module has its own semantic version and `CHANGELOG.md`.
- Tag releases as `<module>-v<version>`, e.g. `uptg-v0.1.0`.
- The root `CHANGELOG.md` records repository-wide changes.

## Milestone cycle

1. Inspect existing files and conventions.
2. Propose the plan and identify risks; wait for approval when architecture or existing files are affected.
3. Implement in small steps.
4. Verify syntax and run the demo scene in Godot 4.7.2.
5. Update docs: module README, `TESTING.md`, `CHANGELOG.md`.
6. Report files created or modified, tests actually run, and known limitations.
7. Propose the next milestone without starting it automatically.

## Bilingual documentation

Every document exists in English (`NAME.md`) and Italian (`NAME.it.md`). When one is changed, update the other in the same commit.

## Large binary assets

Blender sources (`.blend`) and large textures may later move to Git LFS. Until then, keep binary assets small and out of the repository when possible.
