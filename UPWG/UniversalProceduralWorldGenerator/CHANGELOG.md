# UPWG Changelog

## [Unreleased]

### Added
- An editor a child can use (phase A of the plan modelled on the Roblox Studio terrain editor): a top bar (New, Open, Save, Export, Undo, Redo), two tabs, Create (New world, Land, Mountains, Start over) and Edit (Look, Raise, Dig, Smooth, Flatten, Bumpy, Lake, River), big tool buttons with pictures, only the options of the tool in use, rarely needed settings under "More options", and the keys in a line under the view.
- Camera like a game editor (`UPWGCamera`): right button + W A S D (Q E, Shift) to fly, wheel toward the mouse, orbit with the middle button or the Look tool, F to fly to the mouse, buttons to come closer, go farther, see the whole world and look from the sky.
- Shortcuts: Ctrl turns Raise into Dig (and back) and removes water with the water tools, Shift paints with Smooth, B + mouse or wheel sets the brush size, Shift + B the strength, 1 to 8 choose a tool, Ctrl+S saves.
- Brush sizes S, M, L, XL, round or square brush, Flatten modes (both, only lower, only raise) and a fixed height, a brush outline that follows the ground.
- Italian and English (`UPWGI18n`), switched from the top bar and remembered; the first time the system language is used.
- Safety: questions before losing work, autosave every 2 minutes to `user://autosave.upwg.tres` offered at the next start, a question when closing with unsaved changes, undo for water removal.
- Icons from Lucide 0.460.0, ISC license (`editor/icons/`).
- Standalone editor window: templates (island, continent, coast, highlands, flat land) and seeds, terrain and mountain sliders, live 3D preview.
- `UPWGProject`: a whole world in one `.upwg.tres` file, saved and opened from the editor.
- `UPWGExporter`: Godot scene, Godot tiles, 16-bit RAW and EXR heightmaps with their description, glTF terrain mesh and `world.json`.
- Sculpting with the mouse: Raise, Lower, Flatten, Smooth and Roughen brushes with size, strength and soft edge, a ring under the mouse, undo and redo (Ctrl+Z, Ctrl+Y), and Clear all. Strokes are stored as UPRG terrain edits, so they work at any detail.
- Water tools: Lake (click, at any height) and River (click the points, right-click or Enter to finish), with size and depth.
- Worlds up to 30 720 m per side (15 km from the center to the edge). Past 2048 cells per side the world is exported straight from its heights: tiles and heightmap at full detail (up to 8192 cells per side, 4 m cells at 30 km), a lighter glTF, no single scene (ADR-0016, ADR-0017).
- Copies of UPTG, UPRG and UWR kept in sync by `tools/sync_vendor.gd` and checked by the tests.
