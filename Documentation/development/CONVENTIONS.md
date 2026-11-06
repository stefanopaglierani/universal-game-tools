**English** | [Italiano](CONVENTIONS.it.md)

# Coding conventions

Follows the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), with these project rules.

## Naming

| Item | Convention | Example |
|---|---|---|
| Files | `snake_case`, prefixed with module code | `uptg_generator.gd` |
| Classes (`class_name`) | `PascalCase`, prefixed with module code | `UPTGGenerator` |
| Functions, variables | `snake_case` | `build_height_field()` |
| Constants | `UPPER_SNAKE_CASE` | `MIN_RESOLUTION` |
| Scenes | `snake_case.tscn` | `uptg_demo.tscn` |
| Presets | `snake_case.tres` | `island_default.tres` |

Code (names, comments) is written in English.

## GDScript

- Use static typing (`var size: int = 64`, `func f() -> void`).
- Expose configuration through custom `Resource` classes with `@export` and sensible ranges, not hard-coded values.
- Never do generation work every frame; generate on explicit request or initialization.
- Validate inputs and report errors with `push_error()` / `push_warning()`.
- Derive all randomness from a configured seed.

## Documentation

- Every module has a `README.md`, an architecture doc, `TESTING.md` and `CHANGELOG.md`, each with an Italian `.it.md` version.
- Public classes and exported properties have doc comments (`##`).
