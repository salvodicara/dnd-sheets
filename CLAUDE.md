# CLAUDE.md -- Steering Document for AI Agents

## Project Overview

**D&D Sheets** is a zero-dependency, single-file (HTML+CSS+JS) digital character sheet for D&D 2024 players. The entire application lives in `character-sheet.html` (~3,170 lines). There is no build system, no framework, no server. Open the file in a browser and it works.

## Golden Rules

1. **MAIN GOAL: Full UI completeness.** Every single piece of character data must be creatable, editable, and deletable through the UI wizards. A user starting from a blank sheet must be able to build any character (like Catalion) entirely through the app -- no JSON editing, ever. If a data field exists in the model but has no wizard path to set it, that is a **critical bug**. `catalion.json` is the reference: if the wizards can't reproduce it, the app is incomplete.
2. **Single file only.** All code (CSS, HTML, JS) must stay in `character-sheet.html`. Never split into separate files.
3. **Zero dependencies.** No libraries, frameworks, CDNs, or npm packages. Vanilla JS/CSS/HTML only.
4. **Never exceed 100 lines per write operation.** The writing tool fails on large writes. Always use targeted edits or write in small chunks.
5. **Preserve the existing architecture.** Follow the patterns already in the code (see below). Do not introduce new paradigms.
6. **Always test in context.** After any change, mentally verify that `renderAll()` will still produce correct output and that event handlers will bind properly.
7. **Usability first.** Never ask users for technical information (IDs, slugs, anchors). Auto-generate from user-friendly inputs. Wizards should guide step-by-step with contextual labels.
8. **Auto-compute + override.** Every derived value (PB, spell DC, weapon attack, etc.) is auto-calculated. Each has an optional `*Override` field for custom values (magic items, homebrew).
9. **No redundancy in data.** The JSON should store only unique, non-derivable data. The engine is smart. See `DESIGN.md` for the v3.0 data model.
10. **Read DESIGN.md first.** For any new implementation work, read `DESIGN.md` before starting -- it contains all design decisions, the v1 phase plan, and the target data model.
11. **English source code.** ALL identifiers (variable names, function names, CSS classes/IDs, translation keys, section IDs) must be English. Only the string VALUES in `TRANSLATIONS.it` are Italian. If you encounter Italian identifiers in the codebase, rename them to English immediately.
12. **English canonical D&D names.** All fixed D&D names (races, classes, backgrounds, subclasses, conditions, schools, damage types, etc.) are stored in English in the data model. Localization happens only at display time via `dndTr()`. The char-create wizard uses `select-or-custom` fields for these, with a "Custom..." option for homebrew.
13. **No backward compatibility required.** The engine targets v3.0 data format only. When data model changes, update `catalion.json` directly instead of writing migration code.
14. **No commits unless told to.** Never create git commits unless the user explicitly asks.

## Architecture

### File Structure (inside character-sheet.html)

The file is organized in this order:
1. `<style>` block -- CSS with theme variables, component styles, responsive rules
2. `<body>` -- minimal HTML skeleton (splash screen, sidebar, main content area, modal)
3. `<script>` block -- all JavaScript

### CSS Patterns

- **Theme variables:** Two sets of CSS custom properties on `:root[data-theme="dark"]` and `:root[data-theme="light"]`. All colors reference `var(--name)`.
- **Naming:** Lowercase kebab-case class names (`.game-panel`, `.spell-card`, `.hp-bar`).
- **Layout:** CSS Grid for the game panel cards (`auto-fit, minmax(280px, 1fr)`). Flexbox everywhere else.
- **Responsive:** Single breakpoint at `768px` for mobile. Hamburger menu overlay.
- When adding new UI, always use existing CSS variables. Add new variables to BOTH theme blocks.

### JavaScript Patterns

#### Global State
```
CHAR   -- character definition (abilities, spells, weapons, features, etc.)
SESSION -- mutable game state (HP, slots used, log, conditions, etc.)
```
Both are plain objects. All mutations must call `saveAll()` afterward.

#### Rendering
- **String-based templating.** Each section has a `render*()` function that builds an HTML string from `CHAR`/`SESSION`.
- `renderAll()` orchestrates a full re-render by calling all section renderers.
- Event handlers are attached via inline `onclick="funcName(args)"` in the generated HTML strings.
- For live inputs (range sliders, text fields), use `addEventListener` after inserting the HTML.
- After adding a new section, register it in `renderAll()`.

#### Section Architecture
- `SECTION_REGISTRY` maps English section IDs to `{render, label, emoji, deletable, hiddenWhen}`.
- `sectionHeader(sectionId, extra)` builds `<h2>` with emoji from registry + label from `T()`. All render functions use this helper -- never manually build section h2 tags.
- `CHAR.sidebar` is the master layout controller (array of string IDs + separator objects).
- `renderSections()` iterates `CHAR.sidebar` and calls registered renderers.
- `renderSidebar()` renders the sidebar nav from `CHAR.sidebar` via `resolveSidebarItem()`.
- `ensureSidebar()` auto-adds missing built-in sections and features, removes stale entries.
- Game Panel (`#panel`) is pinned at top -- NOT in `SECTION_REGISTRY`, NOT in `CHAR.sidebar`.
- Built-in section IDs: `base-data`, `skills`, `spells`, `weapons`, `equipment`, `algorithm`.
- Custom features: resolved by matching `slugify(feature.title)` against sidebar IDs.
- Separators: `{type:'sep'}` objects in the sidebar array.
- In edit mode, sidebar items show reorder (up/down) and delete controls.

#### Wizard System
- All create/edit operations use the generic wizard engine.
- Wizards are defined in the `WIZARDS` config object. Each wizard has:
  - `title` -- i18n key (resolved via `T()` at render time)
  - `steps[]` -- array of step objects, each with `label` (i18n key) and `fields[]`
  - `onSave(data)` -- callback that mutates `CHAR`/`SESSION` and calls `saveAll(); renderAll();`
- Field `label`, `title`, `placeholder`, `checkLabel` are i18n keys resolved through `T()` by the wizard engine.
- Fields support types: `text`, `number`, `select`, `select-or-custom`, `textarea`, `checkbox`, `group`, `content-blocks`, `emoji`.
- Hooks: `_renderStep(data)`, `_collectData(data)`, `_validateStep(data)`, `_afterRender(data)`, `_buildFields()`.
- To add a new entity type, add a new wizard config and a button that calls `openWizard('wizardName')`.

#### i18n System
- `BASE` object contains all English strings (~330 keys).
- `TRANSLATIONS` object has locale overrides (currently only `it`).
- `T(key)` function (uppercase T) returns the translated string for the current language.
- `dndTr(category, key)` translates D&D-specific terms (conditions, schools, abilities, recovery).
- The `DND` object holds D&D-specific constants with per-language name maps.
- When adding new UI text, add the English string to `BASE` and the Italian translation to `TRANSLATIONS.it`.
- **All translation keys must be English identifiers** (e.g. `addWeapon`, not `aggiungiArma`).
- **Section title translations must NOT include emojis** -- emojis live only in `SECTION_REGISTRY`.
- **Never hardcode user-visible strings** -- always use `T()` or `dndTr()`.

#### Key Functions Reference
| Function | Purpose |
|----------|---------|
| `renderAll()` | Full re-render of all sections |
| `saveAll()` | Persist `CHAR` + `SESSION` to localStorage |
| `openWizard(name, editIndex)` | Open a wizard modal (create or edit) |
| `T(key)` | Get translated string (uppercase T) |
| `sectionHeader(id, extra)` | Build section `<h2>` with emoji from registry |
| `mod(score)` | Compute ability modifier from score |
| `rollDice(formula)` | Parse and roll NdM+K dice formulas |
| `addLog(msg)` | Append to the action log |
| `toast(msg, type)` | Show a toast notification (success/error/info) |
| `renderMarkdown(text)` / `md(text)` | Convert **bold**, *italic*, newlines to HTML |
| `computedPB(level)` | Auto-calculate proficiency bonus from level |
| `slugify(str)` | Convert string to safe kebab-case ID |
| `dndTr(cat, key)` | Translate D&D-specific term |
| `syncSession()` | Ensure SESSION completeness, cleanup stale data |
| `ensureSidebar()` | Auto-populate/clean sidebar array |
| `resolveSidebarItem(item)` | Resolve sidebar entry to full metadata |

## Design Philosophy

This app is designed for **hours-long D&D sessions**. Every visual choice prioritizes eye comfort and readability.

### Color Principles
- **Dark theme:** Use dark greys (`#1a1a2e`), never pure black. Text is warm off-white (`#d8d8e8`), never `#ffffff`. This reduces contrast ratio to a comfortable ~11:1 instead of the harsh ~21:1 of pure black/white.
- **Light theme:** Use warm off-whites (`#f0efe8`), never pure white. Slightly warm/cream tones reduce glare.
- **Accents:** Desaturated (`#9090e0` not `#8c8cff`). Saturated neon colors cause eye fatigue.
- **Borders:** Use `--border-light` for most component borders (subtle). Reserve `--border` for structural dividers (h2 underlines, section separators).

### When Adding New UI
1. Use `--border-light` for card/component borders, `--border` only for section dividers
2. Use `--bg-card2` for nested surfaces, `--bg-card` for primary cards
3. Avoid box-shadow on hover -- prefer border-color transitions
4. Never use pure white text or neon-bright colors
5. Add focus styles with `box-shadow: 0 0 0 2px var(--accent-glow)` for accessibility
6. Test both themes after any visual change
7. **Never hardcode colors for themed elements.** Use CSS variables. If a component needs different colors in light/dark, add new variables to BOTH theme blocks.
8. Semantic colored buttons (danger, heal, rest) must use `--btn-*` variables, not hardcoded hex.
9. Action badges must use `--badge-*` variables for theme-adaptive coloring.
10. The sidebar adapts per theme (dark in dark mode, light in light mode). Use `--sidebar-*` variables, never hardcode `#fff` or `#eee` for hover text -- use `var(--text)`.
11. Element IDs: buttons use `btn-theme`, `btn-lang`, `btn-edit`, `btn-logout`. Always match these exactly in `getElementById()` calls.

## D&D Rules Reference

The sole source of truth for D&D 2024 rules: **http://dnd2024.wikidot.com/**

Always verify game mechanics (point buy costs, spell slot recovery, ability modifiers, proficiency bonus scaling, etc.) against this reference before implementing.

## Wizard UX Philosophy

- Every label should explain *what the user is entering*, not just name the field.
- Use contextual descriptions (e.g., "When do you use this?" not "Title").
- Default emojis: 🔷 for algo blocks, 📄 for features.
- Never ask for technical IDs -- auto-generate via `slugify()`.
- Group related fields logically; use the final step for optional advanced settings.
- In-modal editing for all sub-content (no browser `prompt()` dialogs).

## Auto-Compute + Override Pattern

Every derived value follows the same pattern:
```
const value = CHAR.fieldOverride ?? computeField(CHAR);
```
- If override is set (non-null), use it.
- If override is null/undefined, auto-calculate.
- In the UI, overridden values show a subtle indicator.
- The wizard does NOT ask for derivable values (no PB, DC, attack bonus fields).
- An "override" link in edit mode lets advanced users set custom values.
