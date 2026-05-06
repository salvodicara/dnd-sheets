# Changelog

All notable changes to D&D Sheets are documented here.
Entries are in reverse-chronological order. Uncommitted work appears under `[Unreleased]`.

---

## [Unreleased] — Chronicles Mobile & Sidebar Polish

### Fixed (`chronicles.html`)
- **Mobile sidebar show/hide** — `toggleChrSidebar()` is now mobile-aware: on `≤768px` it toggles `mobile-open` + overlay (like `assistant.html`), on desktop it toggles `collapsed`. Previously the function always ran the desktop collapse path, making the `‹` close button inside the open sidebar a no-op on mobile.
- **Hamburger button** — added `#hamburger-chr` directly in the header (hidden by default, shown on mobile when `body.has-campaign`). Previously the only way to open the TOC sidebar on mobile was buried in the `⋯` overflow menu.
- **Overlay pattern** — `#chr-sidebar-overlay` now uses `.visible` class (same as `#ai-overlay` in `assistant.html`) instead of the `body.chr-sb-mobile-open` body-class hack.
- **Collapsed state leaking into mobile** — `collapsed` class (set on desktop) no longer breaks the mobile sidebar. `toggleChrSidebar()` strips `collapsed` before opening on mobile; a full set of CSS overrides inside `@media(max-width:768px)` resets all collapsed-state rules as a safety net for page load / orientation change.
- **Missing separator below Export in collapsed sidebar** — switched collapsed `.chr-sb-btn` from `border-top` to `border-bottom` so the last action item also has a separator below it, matching `assistant.html`'s `.ai-panel` pattern.
- **Collapsed sidebar icon sizing** — added `min-height:38px` and `font-size:.9rem` to collapsed `.chr-sb-btn`, matching `assistant.html`'s `.ai-panel-hdr` dimensions exactly.
- **Double separator in overflow menu** — removed `#overflow-toc-sep` element and its CSS; the menu now has exactly one `<hr class="overflow-sep">` between nav links and theme/lang utilities, consistent with `index.html` and `assistant.html`.
- **TOC entry removed from overflow menu** — redundant now that a dedicated hamburger button exists. Removed element, 2 CSS rules, JS `applyLang()` reference, and dead `openToc` i18n keys (`en` + `it`).

### Changed (`chronicles.html`)
- **Collapsed sidebar header** — `.chr-sb-header` updated to match `assistant.html`'s `.ai-sb-top`: tighter symmetric padding (`6px 8px`), `justify-content:space-between` when expanded / `center` when collapsed, `border-bottom:rgba(201,162,39,.2)`.
- **Collapsed sidebar toggle button** — `.chr-sb-toggle` updated to match `.ai-sb-toggle`: fixed `28×28px` square, flex-centered, `border-radius:6px`, consistent hover style.
- **Collapsed footer actions** — removed the ugly `36×36` bordered-box style; collapsed `.chr-sb-btn` now renders as a full-width centered-icon row with `border-bottom` separator, identical in rhythm to `assistant.html`'s collapsed panel items. Footer container padding and `border-top` stripped in collapsed state (each button carries its own separator).
- **Separator colors** — header and footer border colors updated from `var(--border-light)` to `rgba(201,162,39,.2)` / `rgba(201,162,39,.12)` to match the accent-tinted separators used throughout `assistant.html`.

---

## [Unreleased] — Campaign Chronicles Query in AI Assistant

### Added (`assistant.html`)
- **📖 Campaign query toggle** — new button in the chat input bar (between 📎 and 🗑). Activates campaign mode: the AI answers questions from the loaded chronicle instead of the character sheet. Turns gold when active.
- **Keyword-based section selection** — chronicle is split by `#`/`##` headings; sections are scored against question keywords and packed greedily into the context budget. Bilingual stopword filtering (English + Italian) ensures clean keyword extraction regardless of chronicle language.
- **AI-generated campaign summary** — when campaign mode is activated with a keyed provider and no cached summary exists, a structured summary (WORLD / PLOT / NPCs / LOCATIONS / OPEN THREADS) is generated silently in the background and cached in `dnd_campaign_summary` localStorage. Auto-detects chronicle language (Italian or English). Stale detection: regenerates if campaign text changes by more than 500 chars.
- **Runtime context strategy:** Pollinations (free) uses cached summary + keyword snippets within 8,000 chars. Keyed providers use keyword selection from full text up to 60,000 chars.
- `sysCampaign` system prompt — lore-focused, instructs AI to stay strictly within chronicle content and not invent details.
- Chronicles nav tab and mobile overflow entry added to `assistant.html` header.

### Added (`index.html`)
- Chronicles tab added to header nav and mobile overflow menu.

### Changed (`Justfile`)
- `just check` now validates `chronicles.html` syntax alongside `index.html` and `assistant.html`.
- `serve` command removed; `run` target restored to `check` + `open index.html`.

### Changed (project structure)
- **Chronicles page promoted to root** — `chronicles/index.html` replaced by `chronicles.html` at project root.
- Example files consolidated into `examples/` folder (`campaign.md`, `catalion_*.json`, PDF).
- **Export filename convention** changed from `name_date.json` to `name_class_lvl_date.json` (e.g. `catalion_di_sancaldo_bard_3_2026-05-06.json`). Class and level are now part of the filename for instant identification.
- Catalion's example JSON renamed accordingly.

---

## [10dcd3b] — Background ASI + pinNotes; Chronicles Page

### Added
- **Phase 34 — Background ASI:** `CHAR.backgroundAsi` field stores background ability bonuses (+2/+1 or +1/+1/+1) separately from `CHAR.abilityScores` (base point-buy only). `finalScores(char)` helper merges both for all calculations. All 10+ computation sites (skills, saves, spells, weapons, initiative) updated.
- **Background ASI wizard step:** New step in char-create wizard between ability scores and combat. Mode toggle (+2/+1 vs +1/+1/+1). Dropdowns constrained to PHB 2024 eligible abilities per background (`DND.backgroundAsiAbilities`).
- **Background Bonuses info row:** New row in Base Data character info table (e.g. `+2 CHA, +1 DEX`). Hidden when no bonuses set.
- **Background ASI tooltip:** Ability score cells for background-boosted abilities show `cursor:help` + tooltip (e.g. `Base: 15 + 2 (Entertainer)`).
- **`pinNotes(text)` helper:** Auto-prepends `📌 ` to each non-empty line of notes fields at render time. Applied to spell, weapon, and equipment renderers. Data never stores manual pin emoji.
- **Chronicles page (`chronicles.html`):** Standalone campaign reader/editor. Renders `.md` or `.txt` files with a sidebar TOC (headings), edit mode with auto-save, export button. Campaign stored in `dnd_campaign_v1` localStorage. Collapsible/resizable sidebar, flash-prevention inline script, bilingual (EN/IT).

### Data (Catalion)
- `abilityScores` corrected to base point-buy values (STR:8 DEX:15 CON:14 INT:8 WIS:10 CHA:15); `backgroundAsi: {"DEX":1,"CHA":2}` added for Entertainer background. Final scores unchanged.
- Manual `📌` stripped from spell `notes` fields (Frantuma) and spell `description` fields (Illusione Minore, Invisibilità) — pin emoji now rendered automatically by `pinNotes()`.

---

## [7e0236a] — Catalion: Fix Level-3 Spell List

### Data (Catalion)
- Removed `"Segreti Magici Bonus"` feature — Magical Discoveries unlocks at level 6, not 3
- Dropped Aid and Hold Person spells (relied on Segreti Magici Bonus)
- Dropped Friends cantrip (level 3 = 2 cantrips, not 3)
- Cleaned up `customConditions` and `sidebar` to match
- Updated combat algorithm: removed Aid pre-combat step; replaced Hold Person branch with Tasha's / Shatter / Dissonant Whispers decision tree

---

## [6a254d9] — Fix HP/Aid Mechanics, Log Persistence, dndTr Fallback, Translations

### Added
- Spell slot usage now logs remaining slots (e.g. "Slot 2 usato — rimasti 2")
- Tracker usage now logs remaining uses
- `logAidUp` / `logAidDown` i18n keys (EN + IT) for Aid grant/expiry log messages

### Fixed
- **HP/Aid effective max:** `effMax` now always computed as `hp.max + aidBonus` — was incorrectly conditioned on `SESSION.hp.current` existence, causing Aid bonus to silently vanish on fresh load
- **Aid dialog:** changing Aid bonus now correctly adjusts `SESSION.hp.current` up (clamped to new effMax) or down; logs the change as heal/damage
- **Action log persistence:** log entries now restored from `SESSION.logEntries` on render — log was blank after every page reload
- **`dndTr()` fallback:** now tries `DND[cat][key]` before returning raw key — fixes untranslated English terms when no locale override exists
- **Italian translations:** `expertise` → `"Maestria"`, `profType_halfProficiency` → `"Mezza Competenza"`, `aidBonus` label → `"PF max (aiuto)"`
- **HP cap in level-up and long rest:** current HP now correctly capped at `hp.max + aidBonus`, not bare `hp.max`
- **Concentration input layout:** input now `flex:1;min-width:0` to prevent overflow; cancel button gets `flex-shrink:0`

### Updated (`assistant.html`)
- AI schema prompt updated: weapons vs equipment warning added; `currency`, `inspiration`, `exhaustion`, `lore`, `preparedMax`, `weaponProficiencies`, `armorProficiencies` added to schema; `sysShort` and `sysBuild` session templates updated

---

## [edb4c0e] — Mobile UX: Nav Visibility + Touch Drag

### Added
- Mobile overflow menu (`⋯`) now includes page nav links: `"✨ AI"` on `index.html`, `"📜 Character"` on `assistant.html`; desktop retains both Character + AI tabs
- Touch drag for sidebar section reordering — HTML5 DnD API is mouse-only; new system uses `touchstart`/`touchmove`/`touchend` + `elementFromPoint()` for drop-target detection; supports reorder and trash-delete; `{passive:false}` listeners coexist with portrait pinch-zoom

### Fixed
- `.overflow-item` anchor elements: added `text-decoration:none` so nav links render cleanly

---

## [ffff4ec] — v1.2 UI Polish, Mobile UX, Content Block Preview Fix, Catalion Restructure

### Added
- Gold/navy accent palette: dark `#c9a227`, light `#8a6800`; applied consistently across both files
- Header bottom border `2px solid var(--accent)` as structural divider
- `h2` section headers: gold accent left-border (4px), uppercase, letter-spacing, font-weight:700
- Active tab reserved underline slot (`border-bottom:2px solid transparent`) — no layout shift between pages
- Mobile overflow menu (`⋯` button) on ≤768px exposes theme/lang toggles
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
