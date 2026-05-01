# CLAUDE.md — Steering Document for AI Agents

## Project Overview

**D&D Sheets** is a zero-dependency, single-file (HTML+CSS+JS) digital character sheet for D&D 2024 players. The entire application lives in `index.html` (~4,492 lines). There is no build system, no framework, no server. Open the file in a browser and it works.

## Golden Rules

1. **MAIN GOAL: Full UI completeness.** Every single piece of character data must be creatable, editable, and deletable through the UI wizards. A user starting from a blank sheet must be able to build any character (like Catalion) entirely through the app -- no JSON editing, ever. If a data field exists in the model but has no wizard path to set it, that is a **critical bug**. `catalion.json` is the reference: if the wizards can't reproduce it, the app is incomplete.
2. **Single file only.** All code (CSS, HTML, JS) must stay in `index.html`. Never split into separate files.
3. **Zero dependencies.** No libraries, frameworks, CDNs, or npm packages. Vanilla JS/CSS/HTML only.
4. **Never exceed 100 lines per write operation.** The writing tool fails on large writes. Always use targeted edits or write in small chunks.
5. **Always syntax-check after edits.** After any JS change, run `just check` from the project root. Never leave a session without a clean check. Common pitfall: mixing `??` with `||`/`&&` requires explicit parentheses.
6. **No dice rolling.** The app never rolls dice. Players always roll in an external window/app. Any feature that needs a dice result must show the formula (e.g. `2d8+3`) and let the user enter the rolled result manually. Never use `Math.random()` for dice. Remove `rollDice()` if found.
7. **Preserve the existing architecture.** Follow the patterns already in the code (see below). Do not introduce new paradigms.
8. **Always test in context.** After any change, mentally verify that `renderAll()` will still produce correct output and that event handlers will bind properly.
9. **No dead code.** Every change must leave the codebase cleaner than it found it. When replacing CSS rules, HTML elements, or JS variables/functions, immediately remove the old ones. When adding i18n keys, verify they are actually used. When removing UI elements, remove their CSS and any DOM-update references. Dead code is a bug.
10. **Usability first.** Never ask users for technical information (IDs, slugs, anchors). Auto-generate from user-friendly inputs. Wizards should guide step-by-step with contextual labels.
11. **Auto-compute + override.** Every derived value (PB, spell DC, weapon attack, etc.) is auto-calculated. Each has an optional `*Override` field for custom values (magic items, homebrew).
12. **No redundancy in data.** The JSON should store only unique, non-derivable data. The engine is smart. See `DESIGN.md` for the v3.0 data model.
13. **Read DESIGN.md first.** For any new implementation work, read `DESIGN.md` before starting -- it contains all design decisions, the v1 phase plan, and the target data model.
14. **English source code.** ALL identifiers (variable names, function names, CSS classes/IDs, translation keys, section IDs) must be English. Only the string VALUES in `TRANSLATIONS.it` are Italian. If you encounter Italian identifiers in the codebase, rename them to English immediately.
15. **English canonical D&D names.** All fixed D&D names (races, classes, backgrounds, subclasses, conditions, schools, damage types, etc.) are stored in English in the data model. Localization happens only at display time via `dndTr()`. The char-create wizard uses `select-or-custom` fields for these, with a "Custom..." option for homebrew.
16. **Backward compatibility: ask before breaking.** The app is deployed and real users have saved JSON. Prefer additive changes (new fields with safe defaults). If a breaking data model change would lead to significantly better design, **ask the user first** — don't just do it. If approved, add a silent migration in `syncSession()` / `ensureSidebar()` so old data upgrades automatically.
17. **No commits unless told to.** Never create git commits unless the user explicitly asks.
18. **Grill before building.** Before implementing any new feature or meaningfully modifying an existing one, always load the `grill-me` skill and interview the user to resolve all design decisions. Do this implicitly — the user does not need to ask for it.

## Architecture

### File Structure (inside index.html)

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
CHAR    -- character definition (abilities, spells, weapons, features, etc.)
            Also holds: levelUpChecklist [{text,done}] (persisted until dismissed),
                        showGettingStarted flag is in SESSION (cleared after first-time card)
SESSION -- mutable game state (HP, slots used, log, conditions, etc.)
            Includes: hp.current/temp/aidBonus, hitDice.used, trackers{}, spellSlots{},
                      gold, round, concentration, initiative, conditions[], deathSucc/Fail,
                      notes, portrait, logEntries[], showGettingStarted, hdDialog
```
Both are plain objects. All mutations must call `saveAll()` afterward.
Both `CHAR` and `SESSION` are saved to localStorage on every `saveAll()` and included in
every JSON export — so mid-session state (current HP, spent slots, tracker uses) is always
fully persisted across reloads and device transfers.

Wizard-related globals (managed by wizard lifecycle):
```
WIZ_DATA      -- collected wizard data across steps
WIZ_KEY       -- current wizard name (set in openWizard, cleared in closeWizard)
WIZ_BLOCKS    -- content blocks array for feature wizard
WIZ_TAGS      -- tags array [{label,color}] for feature/spell/weapon wizards
WIZ_TRACKERS  -- trackers array for feature wizard step 3
WIZ_ACTIONS   -- actions array for feature wizard step 3
WIZ_ALGO_STEPS -- algo steps array for algorithm wizard
CB_EDIT_IDX   -- index of content block being edited inline (-1 = none)
CB_EDIT_DATA  -- deep clone of block being edited (for cancel/restore)
```

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
- Game Panel (`game-panel`) is a regular built-in section in `SECTION_REGISTRY` and `CHAR.sidebar`. Draggable/reorderable like all other sections. No section header (visually distinct card container). `renderPanel()` fills its `<div id="game-panel">` placeholder and binds live listeners; called by `renderSections()` after innerHTML and by tracker interactions.
- Built-in section IDs: `game-panel`, `base-data`, `skills`, `spells`, `weapons`, `equipment`, `algorithm`.
- Custom features: resolved by matching `slugify(feature.title)` against sidebar IDs.
- Separators: `{type:'sep'}` objects in the sidebar array.
- In edit mode, sidebar items show drag handles for reorder and a trash drop zone for deletion.

#### Equipment-Based Tracking
- Standalone `CHAR.trackers[]` was removed. All trackers are now either feature-embedded or equipment-based.
- Equipment items with `tracked: true` show as pip trackers in the game panel.
- Equipment tracker session IDs use `eq-` prefix: `eq-${slugify(e.name)}`.
- Equipment wizard conditionally shows tracker fields (quantity, emoji, recovery, isPotion, potionFormula) when "Track quantity" is checked.
- `deleteEquip()` cleans up SESSION tracker data.
- `longRest()` resets equipment trackers respecting the `recovery` field.

#### Weapons in Equipment
- Weapons auto-appear in the equipment table as derived rows — no manual duplication.
- Weapon rows show damage/properties as notes, styled with `.equip-weapon-row` (italic, muted).
- Edit/delete on weapon rows call `editWeapon(idx)` / `deleteWeapon(idx)` — goes through weapon wizard.
- Single source of truth: weapons array is authoritative, equipment just renders them.

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
- Field hints render as hover tooltips (`title` attribute + `ⓘ` icon), not visible `<div>` elements.

#### Tag System
- Features, spells, and weapons support `tags: [{label, color}]` — array of 0-3 tags.
- Preset colors: `green`, `blue`, `purple`, `red`, `orange`. CSS vars: `--tag-green`, etc.
- `WIZ_TAGS=[]` global populated from `prefill.tags` in `openWizard()`, cleared in `closeWizard()`.
- `renderTags(tags)` renders tags as `<span class="feature-tag tag-{color}">`.
- Tag editor injected via `_afterRender` in feature/spell/weapon wizard steps.

#### Live Wizard Preview
- `WIZ_KEY` global tracks current wizard name (set in `openWizard()`, cleared in `closeWizard()`).
- Four preview functions: `renderFeaturePreview()`, `renderSpellPreview()`, `renderWeaponPreview()`, `renderAlgoPreview()`.
- Four inject functions: `injectFeaturePreview()`, `injectSpellPreview()`, `injectWeaponPreview()`, `injectAlgoPreview()`.
- Generic dispatcher: `injectWizPreview()` checks `WIZ_KEY` and calls the right inject function.
- All preview-enabled wizard steps have `_afterRender` hooks. Step 1 fields have live `input`/`change` listeners.
- CSS: `.wiz-preview` (dashed border box), `.wiz-preview-label`, `.wiz-preview-content` (pointer-events:none).

#### Tracker/Action Page-Replacement UX
- `editWizTracker(i)` and `editWizAction(i)` replace entire `wiz-body.innerHTML` with a dedicated editor form.
- Save/cancel calls `renderWizardStep()` to restore step 3.
- `collectTrkEdit(i)` / `collectActEdit(i)` — extracted data-collection helpers.
- `wizNext()` auto-saves any active tracker/action edit. `wizBack()` intercepts and cancels active edits.

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
| `addLog(msg)` | Append to the action log |
| `toast(msg, type)` | Show a toast notification (success/error/info) |
| `renderMarkdown(text)` / `md(text)` | Convert **bold**, *italic*, newlines to HTML |
| `computedPB(level)` | Auto-calculate proficiency bonus from level |
| `slugify(str)` | Convert string to safe kebab-case ID |
| `dndTr(cat, key)` | Translate D&D-specific term |
| `syncSession()` | Ensure SESSION completeness, cleanup stale data |
| `ensureSidebar()` | Auto-populate/clean sidebar array |
| `resolveSidebarItem(item)` | Resolve sidebar entry to full metadata |
| `renderTags(tags)` | Render tag badges as HTML spans |
| `injectWizPreview()` | Dispatch live preview update for current wizard |
| `translateSource(src)` | Translate feature source for display |
| `initSbResize()` | Attach drag listener to `#sb-resize` handle |
| `updateFixedControls()` | Sync header tab labels and theme/lang buttons |

## AI Assistant (`assistant.html`)

A standalone ~1,229-line HTML file (same zero-dependency constraint). Communicates with `index.html` exclusively via `localStorage` key `dnd_sheet_v2`.

### Sidebar Layout

`#ai-sidebar` is `position:fixed; left:0; top:48px; width:var(--ai-sb-w,240px)`, matching the `#sidebar` pattern in `index.html`.

- **Collapsible:** `.collapsed` class + `--ai-sb-w:48px` shrinks to icon-only strip. State saved to `aiSidebarCollapsed` in localStorage.
- **Resizable:** `#ai-sb-resize` drag handle (160px–400px). Width saved to `aiSidebarWidth` in localStorage. Handle hidden when collapsed.
- **Two panels:** ⚙️ Settings (`#setup-panel`) and 🧙 Character (`#cpanel-panel`). Toggled via `.ai-panel.open` class. Start collapsed by default; `openAiPanel('setup')` auto-expands on new-user welcome.
- **Mobile:** overlay drawer via `#ai-overlay` + `mobile-open` class; hamburger `#hamburger-ai` in header.
- **Flash prevention:** An inline `<script>` in `<head>` runs synchronously before first paint, applying `data-theme`, `--ai-sb-w`, and `disclaimer-dismissed` class from localStorage. This prevents layout/theme flash on page load and navigation.
- **CSS variable note:** `assistant.html` defines `--bg3` (not `--bg-card2`). Always use `var(--bg3)` for hover surfaces in this file.

### Disclaimer

`#ai-disclaimer` bar at bottom of chat, dismissible via `dismissDisclaimer()`. Dismissed state saved to `aiDisclaimerDismissed` in localStorage and applied before paint via `html.disclaimer-dismissed #ai-disclaimer{display:none}`.

### State
```
HISTORY      -- OpenAI-format message array [{role, content}]
CHAR         -- full character object loaded from localStorage ({version, character, session})
CHAR_DONE    -- boolean flag: has the character been injected into HISTORY yet?
STAGED_FILE  -- {name, text} when a document is attached; null otherwise
```

### Send Flow
1. On first send, inject character as synthetic `HISTORY[0/1]` (user+assistant turns), stripping `session.portrait` (base64) and `session.logEntries` (unbounded) to save tokens. Set `CHAR_DONE = true`.
2. Append the real user message and call the provider API.
3. After the AI responds, push the assistant reply to `HISTORY`.

### Document Import Flow
- Paperclip button (`#btn-attach`) triggers a hidden file input (`#doc-file`, accepts `.txt,.pdf,.docx`).
- File is parsed client-side by `parseDocumentFile(file)` → dispatches to `extractPdfText()`, `extractDocxText()`, or `file.text()`.
- PDF extraction: Method 1 = AcroForm `/V` field scanner (handles official WotC fillable PDFs with UTF-16BE encoding); Method 2 = BT/ET text fallback for simple PDFs.
- DOCX extraction: ZIP local header parser → `DecompressionStream('deflate-raw')` → `<w:t>` XML text extraction.
- Parsed text is stored in `STAGED_FILE`; a chip shows the filename with a ✕ to remove it.
- **On send, two modes:**
  - **No user text** → build mode: clears `HISTORY`, uses `sysBuild` system prompt, AI outputs a full `json-char` block for import.
  - **User text present** → context mode: document injected into the message, history preserved, regular system prompt used.
- `importChar(uid)` normalizes the parsed JSON, preserves portrait/logEntries, sets `session.hp.current = hp.max`, saves to localStorage, updates `#cname`, resets `CHAR_DONE = false`.

### JSON Patch Protocol
- AI is always instructed to return a ` ```json-patch` `` ` block (RFC 6902 ops array) at the end of every character-update response, after the prose and wizard steps.
- AI must **never** expose technical details (array indices, JSON paths, field names) in prose — only in the patch block.
- For pure rules questions with no sheet change, the patch block is omitted.

### `render(text)` Pipeline
| Code block type | Content | Result |
|---|---|---|
| ` ```json-patch` `` ` | Valid ops array | "Apply changes" button |
| ` ```json-patch` `` ` | Malformed / truncated | Subtle `⚠` hint in user's language |
| ` ```json-char` `` ` | Valid character object | "Import character" button |
| ` ```json` `` ` | Array of `{op,path}` objects | Auto-detected as patch → Apply button |
| ` ```json` `` ` | Object with `.character` or `.version:'3.0'` | Auto-detected as character → Import button |
| ` ```json` `` ` | Anything else | Silently dropped (no output) |
| Prose | `### heading` | Rendered as `<strong>` bold |
| Prose | `**bold**` / `*italic*` | Standard inline formatting |

### Apply Flow (`applyPatch(uid)`)
1. `applyJsonPatch(CHAR, ops)` — minimal RFC 6902 (`add`, `remove`, `replace`). For `add`, missing intermediate paths are auto-created.
2. `mergeSession()` — re-inject `portrait` and `logEntries` from in-memory `CHAR` (the AI never sees or modifies these).
3. `localStorage.setItem('dnd_sheet_v2', ...)` — saves updated character.
4. `CHAR = updated` — keeps in-memory state fresh.
5. `HISTORY[0]` overwritten in-place with the updated character JSON (re-sync without history bloat).
6. `#cname` panel updated immediately.
7. `toast(UI('applyToast'))` — stays in chat, no redirect.

### i18n (`STRINGS` + `UI()`)
Same pattern as `index.html` but independent. `STRINGS.en` and `STRINGS.it` hold all user-visible strings. `UI(key, ...args)` resolves with fallback to English. Function-valued keys (e.g. `modelInfo`) receive args via spread.

### Provider Config (`PROVS`)
| Provider | Auth | Notes |
|---|---|---|
| `pollinations` | None (`noKey:true`) | `maxHistory:6`, uses `sysShort` prompt, fetches live model info from `https://text.pollinations.ai/models` |
| `gemini` | API key | Non-streaming, Gemini format |
| `groq` | API key | Streaming SSE, OpenAI-compat |
| `openrouter` | API key | Streaming SSE, OpenAI-compat |
| `openai` | API key | Streaming SSE |

### Key Functions (`assistant.html`)
| Function | Purpose |
|---|---|
| `send()` | Build/context/normal message dispatch, call provider, render response |
| `render(text)` | Parse code blocks + markdown, return HTML |
| `applyPatch(uid)` | Apply stored RFC 6902 ops, save, re-sync, update `#cname` |
| `importChar(uid)` | Import full character object, reset session HP, update `#cname` |
| `applyJsonPatch(obj, ops)` | Pure RFC 6902 engine (add/remove/replace) |
| `mergeSession(jsonStr)` | Re-inject portrait + logEntries before save |
| `stageFile(event)` | Pick file, parse it, show chip |
| `clearStagedFile()` | Clear STAGED_FILE and hide chip |
| `parseDocumentFile(file)` | Dispatch to txt/pdf/docx extractor |
| `extractPdfText(buf)` | AcroForm field scanner + BT/ET fallback |
| `extractDocxText(buf)` | ZIP + deflate-raw + XML `<w:t>` extractor |
| `decodePdfStr(s)` | UTF-16BE + PDF octal escape decoder |
| `toast(msg)` | Transient notification (stays in chat) |
| `fetchPollinationsLimits()` | Fetch live model info for settings hint |
| `UI(key, ...args)` | Translated string lookup with en fallback |
| `buildSetup()` | Render provider settings panel |



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

## Full JSON Schema

This is the canonical schema for both development reference and the AI assistant's system prompt (`assistant.html`). Keep both in sync when adding new fields.

The exported file shape: `{ version:"3.0", savedAt, character:{...}, session:{...} }`

### CHAR — top-level fields
```
name                      string
quote                     string (flavor text / motto)
race                      string
class                     string
subclass                  string
level                     integer 1–20
background                string
alignment                 string
playerName                string
speed                     string — e.g. "9 m"
ac                        number
armorNote                 string — e.g. "Leather +DEX"
hp                        { max: number }
hitDieType                number — 4|6|8|10|12
initiativeBonus           number (optional flat bonus on top of DEX mod)
languages                 string (comma-separated)
toolProficiencies         string
abilityBudget             number (default 27)
proficiencyBonusOverride  number|null  (null = auto from level)
levelUpChecklist          [{text:string, done:boolean}] | null
```

### CHAR.abilityScores
```
{ STR, DEX, CON, INT, WIS, CHA }   all integers
```

### CHAR.savingThrows
```
string[]   ability codes with save proficiency — e.g. ["DEX","CHA"]
```

### CHAR.skills
Map of skill → proficiency. Omit skills with no proficiency.
```
Keys: acrobatics · animalHandling · arcana · athletics · deception · history
      insight · intimidation · investigation · medicine · nature · perception
      performance · persuasion · religion · sleightOfHand · stealth · survival
Values: "proficient" | "expertise" | "halfProficiency"
```

### CHAR.spellcasting
```
ability              "CHA"|"INT"|"WIS"
preparedCaster       boolean  (Cleric/Druid/Paladin/Wizard prepare from list)
focus                string — e.g. "Arcane focus", "Musical instrument"
spellDCOverride      number|null
spellAttackOverride  number|null
```

### CHAR.spellSlots[] (each slot tier)
```
level      integer 1–9
total      integer
pactMagic  boolean (omit if false) — recovers on short rest
```

### CHAR.spells[] (each spell)
```
level          0=cantrip, 1–9
name           localized display name
originalName   English D&D 2024 name (ALWAYS present, ALWAYS English)
emoji          string
actionType     "action"|"bonus"|"reaction"|"free"
school         Evocation|Enchantment|Illusion|Abjuration|Conjuration|Divination|Necromancy|Transmutation
range          string — e.g. "18 m", "Touch", "Self"
concentration  boolean (omit field entirely if false)
duration       string — e.g. "Instantaneous", "1 minute", "Concentration, up to 1 hour"
saveAbility    "STR"|"DEX"|"CON"|"INT"|"WIS"|"CHA"  (omit if no saving throw)
description    string — supports **bold**, *italic*, \n line breaks
scaling        string (omit if no upcast scaling) — e.g. "+1d6 per slot above 1st"
notes          string (omit if none) — "📌 tactical tip"
tags           [{label:string, color:"green"|"blue"|"purple"|"red"|"orange"}]
prepared       boolean (omit unless preparedCaster:true)
```

### CHAR.weapons[] (each weapon)
```
name                string
quantity            integer
emoji               string
damageDie           string — e.g. "1d8"
damageType          string — e.g. "Piercing", "Slashing", "Bludgeoning"
attackStat          "STR"|"DEX"
attackBonusOverride number|null  (null = auto: stat mod + PB)
damageModOverride   number|null  (null = auto: stat mod)
properties          string — e.g. "Finesse, Versatile (1d10), Thrown (6/18 m)"
notes               string
tags                [{label, color}]
```

### CHAR.equipment[] (each item)
```
name           string
emoji          string (optional)
notes          string
tracked        boolean — if true, shows pip tracker in game panel
quantity       integer  (required if tracked)
recovery       "long"|"short"|"manual"  (required if tracked)
isPotion       boolean (optional) — tapping auto-heals via potionFormula
potionFormula  string (required if isPotion) — e.g. "2d4+2"
```

### CHAR.features[] (each feature / class ability)
```
title      string
emoji      string
source     string — e.g. "Bard", "College of Lore", "Origin Feat", "Combat Rule"
sectionId  string (auto-generated by slugify — never set manually in JSON)
tags       [{label, color}]
contentBlocks  array of content block objects (see below)
trackers       array of tracker objects (see below) — omit if none
actions        array of action objects (see below) — omit if none
```

Content block types:
```
{type:"paragraph", text:"..."}
{type:"note",      text:"📌 ..."}
{type:"bullets",   bullets:["item 1","item 2"]}
{type:"table",     rows:[["Label","Value"], ["Range","18 m"]]}
{type:"subfeature", title, emoji, tags:[], contentBlocks:[...]}
```

Tracker object (within a feature):
```
label     string (optional — shown as pip label)
emoji     string (optional)
total     integer
recovery  "long"|"short"|"manual"
die       string (optional) — e.g. "d6", displayed on the pip
showDie   boolean (optional)
```

Action object (within a feature — shown in game panel action bar):
```
label       string (optional)
emoji       string (optional)
type        "action"|"bonus"|"reaction"|"free"
description string — short one-line summary for the action badge
```

### CHAR.combatAlgorithm[] (decision-tree combat guide)
```
emoji   string
title   string — e.g. "TURN 1", "REACTION"
steps   [{question?:string, indent?:boolean, bullets:string[]}]
```

### CHAR.customConditions
```
string[]   extra condition labels shown in game panel — e.g. "Aid active (+5 HP)"
```

### CHAR.sidebar
```
(string | {type:"sep"})[]
Built-in IDs: "game-panel" "base-data" "skills" "spells" "weapons" "equipment" "algorithm"
Feature IDs:  slugify(feature.title)
Separators:   {type:"sep"}
```

### SESSION object
```
hp              { current, temp, aidBonus }
hitDice         { used }
trackers        { [id:string]: { used } }   — id = slugify(label||featureTitle) or "eq-"+slugify(name)
spellSlots      { [level:string]: { used } }
gold            number
round           number
concentration   string
initiative      string
conditions      string[]
deathSucc       number
deathFail       number
notes           string
portrait        string|null  (base64 data URL — preserve exactly, never truncate)
logEntries      [{text, type, ts}]
showGettingStarted  boolean
hdDialog        boolean
```

---
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
