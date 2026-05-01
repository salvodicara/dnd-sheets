# Changelog

All notable changes to D&D Sheets are documented here.
Entries are in reverse-chronological order. Uncommitted work appears under `[Unreleased]`.

---

## [Unreleased] — UI Redesign, Mobile UX, UX Polish (v1.2)

### Added
- Gold/navy accent palette: dark `#c9a227`, light `#8a6800`; consistent across both files
- Header bottom border `2px solid var(--accent)` as structural divider
- `h2` section headers: gold accent left-border (4px), uppercase, letter-spacing, font-weight:700
- Active tab reserved underline slot (`border-bottom:2px solid transparent`) — no layout shift between pages
- Mobile overflow menu (`⋯` button) on ≤768px exposes theme/lang toggles; identical in both files
- Portrait lightbox: click portrait → full-screen overlay with scroll/pinch zoom; ESC or click-outside to close; "📷 Change photo" + "Close" buttons
- Sidebar character block (`.sb-char-info`) clickable — smooth scrolls to page top with hover highlight
- Scroll anchor margin (`scroll-margin-top:68px`) on `h2`, `.spell-level-title`, and `#game-panel` — sidebar nav links no longer land under fixed header
- `overflowTheme` / `overflowLang` i18n keys (EN + IT) in both files

### Fixed
- Mobile `assistant.html`: send button and chat input no longer hidden behind mobile browser chrome (`html,body{height:100dvh}`)
- Mastery tooltip `z-index` raised to `210` — now always renders above the fixed sidebar (`z-index:200`)
- `just check` Justfile strengthened to also validate main JS block in `assistant.html`
- Root crash in `buildPanelRow3()`: missing `const C=CHAR` caused entire `renderAll()` chain to abort (blank tabs, no FAB, empty game panel)
- `DEFAULT_SIDEBAR` order corrected: `spells` after `skills`, `character-lore` before `algorithm`
- `.hdr-tabs` hidden on mobile (`display:none!important` in `@media(max-width:768px)`) in both files
- Content block preview (wiz-preview) not rendered on initial wizard open — `injectWizPreview()` now called at the end of `renderWizardStep()` field-based path
- Block summary in `renderContentBlockEditor()` showed raw number (e.g. "2") for table blocks — synced template with `refreshCBEditor()` to show "2 rows"; also fixed bullets blocks showing blank
- `WIZ_BLOCKS` shallow-spread in `openWizard()` replaced with `JSON.parse(JSON.stringify(...))` deep-clone — prevents wizard edits from silently mutating live `CHAR` data before save

### Changed
- Header height 48px → 50px; all dependent `top`/`margin-top`/`height:calc(...)` offsets updated in both files
- Portrait click: opens lightbox if portrait exists, file picker if not (was always file picker)
- `.sb-change-char` button text-align changed from `left` to `center`

### Data (Catalion)
- Features restructured: `"College of Lore"` and `"Feat Origin"` wrapper features removed; subfeatures promoted to top-level features (`"Parole Taglienti"`, `"Segreti Magici Bonus"`, `"Musicista"`, `"Fortunato"`) with correct `source` values
- `"Lucky"` renamed to `"Fortunato"` throughout (feature title, tracker label, session tracker key)
- `"Two-Weapon Fighting"` renamed to `"Lotta con Due Armi"`
- `"Expertise (Perizia)"` renamed to `"Perizia"`, `"Jack of All Trades"` renamed to `"Jolly di Tutto"`
- Sidebar IDs updated to match new slugified feature names; College of Lore and Origin Feat groups each get their own separator block

---

## [3bb1b63] — Phases 21-30: D&D 2024 Feature Parity

### Added
- **Phase 21:** Passive Perception, Investigation, Insight — auto-computed in Skills section (10 + mod + proficiency)
- **Phase 22:** Inspiration toggle (`SESSION.inspiration`) and Exhaustion 0–6 (`SESSION.exhaustion`) in game panel; long rest reduces exhaustion by 1 per D&D 2024
- **Phase 23:** Multi-currency PP/GP/EP/SP/CP replace single gold field; coin tile selector in game panel; `syncSession()` migrates old `SESSION.gold`
- **Phase 24:** Spell components V/S/M (`compV`/`compS`/`compM` booleans + `compMaterial` string); V/S/M badges on spell cards; material tooltip
- **Phase 25:** Weapon Mastery (Cleave/Graze/Nick/Push/Sap/Slow/Topple/Vex); CSS `::after` tooltip with D&D 2024 descriptions (EN + IT)
- **Phase 26:** Attunement flag (`attuned`) on equipment items; chip on table rows; N/3 badge in equipment section header
- **Phase 27:** Spell filter bar — text search + prepared toggle; scroll position and input focus preserved on re-render
- **Phase 28:** Weapon and armor proficiency free-text fields in char-create wizard (Combat step); displayed in base-data section
- **Phase 29:** Character Lore section — `CHAR.lore` object (age/height/weight/appearance, personality/ideals/bonds/flaws, backstory); dedicated renderer + 2-step wizard
- **Phase 30:** Unarmed Strike auto-derived row in weapons table (1 + STR mod bludgeoning; PB + STR mod attack bonus); not stored in `CHAR.weapons`
- `catalion.json` updated: full Italian backstory, physical stats, spell components, weapon masteries

### Fixed
- DESIGN.md: phases 13-20 documented, schema version consistency, data model, line refs, design decisions 77-90
- `SCHEMA_VERSION = '3.0'` is single source of truth across codebase

---

## [74ae7d6] — UI Polish: Assistant Topbar, Resizable Sidebars

### Added
- Resizable sidebar via drag handle (`#sb-resize` / `#ai-sb-resize`) in both files; width persisted to localStorage
- Sidebar collapse state persisted in localStorage (`aiSidebarCollapsed`)
- Flash-prevention inline `<script>` in `assistant.html` `<head>` applies theme + sidebar state before first paint

### Fixed
- `assistant.html` topbar alignment with `index.html`

---

## [9544273] — Document Import in Assistant

### Added
- Paperclip attach button: import `.txt`, `.pdf`, `.docx` files into AI chat
- PDF extraction: AcroForm `/V` field scanner (WotC fillable PDFs, UTF-16BE) + BT/ET text fallback
- DOCX extraction: ZIP local header parser + `DecompressionStream('deflate-raw')` + XML `<w:t>` extraction
- Build mode: attached doc + no user text → clear history, use `sysBuild` prompt, AI outputs full `json-char` block for import
- Context mode: attached doc + user text → document injected into message, history preserved
- `importChar(uid)`: normalizes parsed JSON, preserves portrait/logEntries, sets `session.hp.current = hp.max`

---

## [419b728] — Fix Assistant: Schema v3.0, Groq 70B, Patch Robustness

### Fixed
- `assistant.html` updated to schema v3.0 data model
- Groq provider updated to `llama3-70b-8192`
- `json-patch` block detection made more robust (handles extra whitespace, partial blocks)
- `HISTORY` persisted across page reloads

---

## [8b737a4] — Phases 13-19: FAB, Getting Started, Level-Up, Session Cleanup

### Added
- **Phase 13:** Floating Action Button (FAB) — edit mode only; Level Up, Add Feature, Add Item, Add Spell (conditional)
- **Phase 14:** Edit mode visual feedback (orange inset glow via `body.edit-mode::after`); banner removed per user decision
- **Phase 15:** Getting Started card — one-time card after char creation; buttons auto-enable edit mode before opening wizard
- **Phase 16:** Level-Up wizard — HP gain (average checkbox pre-checked), persistent checklist in `CHAR.levelUpChecklist`
- **Phase 17:** `syncSession()` prunes stale tracker and spell slot entries for deleted features/equipment
- **Phase 18:** Portrait upload size cap: 512px max, JPEG quality 0.8 (`loadPortrait()` via canvas)
- **Phase 19:** `validateAndMigrateChar()` — validates required fields, clamps level 1–20, defaults ability scores to 10, migrates legacy skills format

---

## [99d03cd] — Fix: Variable Shadowing Bug

### Fixed
- Renamed local `modStr` to `hdModStr` in `buildPanelBottom()` to stop shadowing the global `modStr()` function

---

## [0f5b58f] — Refactor: Remove All Dice Rolling

### Removed
- All `Math.random()` dice logic; app never rolls dice
- `rollDice()` function removed entirely
- Players always roll externally; app shows formulas only (e.g. `2d8+3`)

---

## [7bb439f] — Phase 12: Rest System

### Added
- `shortRest()`: resets short-recovery feature/equipment trackers, resets Pact Magic spell slots, opens HD spending dialog
- HD spending dialog: quantity +/− buttons, Roll & Heal (heals HP, logs result, shows `+N HP` toast), Skip
- `pactMagic` boolean flag on spell slots; Pact Magic slots display own label; reset on short rest (not long)

### Fixed
- `longRest()` now correctly resets all non-manual trackers (was incorrectly skipping `recovery:'short'`)
- `longRest()` shows "🌙 Long rest — fully restored!" toast

---

## [5c33115] — Phase 11: Smart Spell Slot Prompt

### Added
- When saving a new spell with no corresponding slot tier, a deferred info toast appears with "＋ Add Slot" action button pre-filling the slot wizard to that level
- `showToast(msg, type, btn)` extended with optional `btn:{label,fn}` parameter for action buttons

### Fixed
- Toast CSS class mismatch: was `toast toast-info`, corrected to `toast info`

---

## [3b1e70a] — Phases 9-10: Smart Auto-Calc + 6-Step Character Creation

### Added
- Auto-compute + override pattern for PB, spell DC, spell attack bonus, weapon attack/damage — all settable via UI
- `proficiencyBonusOverride` field in char-create wizard (Combat step)
- Spell DC and attack bonus override fields in spellcasting wizard
- Weapon `attackBonusOverride` and `damageOverride` fields in weapon wizard
- 6-step character creation wizard: added Step 5 (Skills) and Step 6 (Spellcasting, optional)
- `DND.casterAbility` map: auto-fills spellcasting ability from class name

---

## [3677269] — Phases 4, 6, 8: Spell Prep, Ritual, No prompt()

### Added
- Spell preparation inline toggle (no edit mode required); unprepared spells dimmed (opacity .45)
- Ritual badge ("R Ritual") on spell cards and wizard live preview
- `preparedCaster` flag auto-set from class in char-create wizard; cantrips always treated as prepared
- All `prompt()` calls replaced with in-modal editing (zero `prompt()` remain)

### Fixed
- Pip visual consistency across both themes (filled = available, hollow = used)
- Death save, pip, and gold colors moved to CSS variables

---

## [61ef866] — Phase 3: Sidebar Architecture + Equipment Tracking

### Added
- `SECTION_REGISTRY` — maps section IDs to `{render, label, emoji, deletable, hiddenWhen}`
- `sectionHeader()` helper — all sections use registry-derived emoji; never build `h2` manually
- `CHAR.sidebar` as master layout controller; `ensureSidebar()` auto-populates/cleans; `resolveSidebarItem()` resolves entries
- Drag-drop sidebar reorder in edit mode; trash drop zone for deletion
- Equipment items with `tracked:true` appear as pip trackers in game panel (`eq-` prefix IDs)
- Weapons auto-derive in equipment table — single source of truth, no duplication

### Removed
- `CHAR.trackers[]` standalone array — replaced by equipment tracking + feature-embedded trackers
- `CHAR.actions[]` array — all actions embedded in features as `actions[]`

---

## [1311113] — Phase 5/7: Tag System, Live Preview, Wizard UX Overhaul

### Added
- Tag system `[{label, color}]` on features, spells, weapons — replaces `isNew`/`isSecret` flags; 5 preset colors
- Live wizard preview for feature, spell, weapon, and algorithm wizards (`WIZ_KEY` dispatcher)
- Field hints converted from visible `<div>` elements to hover tooltips (`title` attribute + ⓘ icon)
- Feature wizard step 3: page-replacement UX for tracker/action editing (no inline row edit)
- Content block inline editors for all block types (paragraph, note, bullets, table, subfeature, header)
- Multiple trackers and actions per feature (`trackers[]`/`actions[]` arrays)

---

## [12ffb36] — Phases 1-2 Completion + Phase 3/6/7 Advance

### Added
- ~340 i18n keys in `BASE` (English) with full `TRANSLATIONS.it` coverage
- English canonical D&D names stored in data model; localized at display time via `dndTr()`
- `select-or-custom` wizard field type — fixed list + "Custom..." option for homebrew
- Tracker IDs auto-generated via `slugify()` with collision handling; users never see technical IDs
- `die`/`showDie` fields added to tracker wizard

---

## [4b990d6] — Phase 1-2: i18n Foundation + Auto-IDs

### Added
- i18n system: `BASE` object (~330 English keys), `TRANSLATIONS.it`, `T()` function, `dndTr()` for D&D terms
- All wizard `label`/`placeholder`/`title` route through `T()`
- All `addLog()` calls use `T()` keys; zero hardcoded Italian strings remain
- Dead translation keys removed; orphaned keys wired to empty states

---

## [9c18b5b] — First Draft

Initial single-file D&D 2024 character sheet. Dark/light themes, basic wizard system, game panel with HP/slots/conditions/log.

---

## [801bb68] — Add PDF

Added PDF reference document.

---

## [377a582] — Add Catalion Sheet

Added reference character JSON (Catalion Livello 3) as the canonical test character.
