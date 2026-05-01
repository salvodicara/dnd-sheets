# DESIGN.md — D&D Sheets v1 / v1.1 Design Document

> **This document is the source of truth for implementation.** Any AI agent picking up
> work on this project should read this file first, then CLAUDE.md.

## Status

- **v0 (Complete):** Core character sheet, wizard system, i18n skeleton, dark/light themes
- **v1 (Complete):** UX overhaul, i18n completion, sidebar architecture, smart features, D&D 2024 parity
- **v1.1 (Scoped, Deferred):** Full level-up wizard, class feature tables, feat database
- **v1.2 (In Progress):** UI redesign (gold/navy palette, header polish), mobile UX, UX polish

---

## Core Design Principle

**Auto-compute everything, but always allow manual override.**

Every derived value (PB, spell DC, weapon attack bonus, etc.) is auto-calculated by the engine.
But each has an optional `*Override` field so the DM or player can set a custom value when
the rules don't cover their situation (magic items, homebrew, etc.).

| Field | Auto-computed from | Override field |
|-------|-------------------|----------------|
| Proficiency Bonus | `2 + floor((level-1)/4)` | `proficiencyBonusOverride` |
| Spell Save DC | `8 + PB + abilityMod(ability)` | `spellcasting.dcOverride` |
| Spell Attack Bonus | `PB + abilityMod(ability)` | `spellcasting.attackBonusOverride` |
| Weapon Attack Bonus | `PB + abilityMod(attackStat) + magicBonus` | `weapon.attackBonusOverride` |
| Weapon Damage | `damageDie + abilityMod(attackStat) + magicBonus` | `weapon.damageOverride` |

UI pattern: show the computed value. In edit mode, a small override icon opens an input.
If overridden, show a subtle indicator (asterisk or color) so the user knows it's manual.

---

## What's Already Done (v0)

- [x] Single-file HTML+CSS+JS character sheet (~2,700 lines)
- [x] Dark theme redesign (comfortable greys, desaturated accents)
- [x] Light theme redesign (warm cream tones)
- [x] Light theme full fix (sidebar, badges, pips, semantic buttons)
- [x] Typography (system font stack, 16px base, antialiased)
- [x] ~20 hardcoded border references softened to --border-light
- [x] Critical edit bug fixed (char-create onSave preserves data on edit)
- [x] Point-buy abilities wizard (D&D standard cost table, budget bar, free mode)
- [x] .gitignore, README.md, CLAUDE.md created
- [x] Wizard system with hooks (_renderStep, _collectData, _validateStep, _afterRender, _buildFields)
- [x] i18n skeleton (BASE + TRANSLATIONS.it + T() + dndTr())
- [x] Game panel with HP, hit dice, death saves, trackers, spell slots, conditions, gold, log
- [x] Sidebar with drag-drop reorder, section picker
- [x] Feature system with content blocks (paragraph, bullets, table, note, header, subfeature)
- [x] Algorithm system with step-by-step decision trees
- [x] Export/import JSON, session save/load
- [x] Mobile responsive (hamburger menu, overlay sidebar)

---

## v1 Implementation Plan

### Phase 1: i18n Completeness
**Status:** ✅ COMPLETE
**Goal:** All source keys English, zero hardcoded Italian, proper translations everywhere.

Done:
- ~340+ keys in BASE (English) with matching TRANSLATIONS.it
- All WIZARDS definitions use T() for labels, placeholders, titles
- All addLog() calls use T() keys
- hpAbbr, logNoHD, logSlotUsed, etc. all i18n'd
- Dead keys removed, orphaned keys wired to empty states

### Phase 2: Auto-Generate Technical IDs
**Status:** ✅ COMPLETE
**Goal:** Users never see or type technical IDs.

Done:
- Tracker IDs auto-generated via slugify(label) with collision handling
- Dead action ID field removed
- Sidebar uses ID-only strings, labels derived from registry/features
- die/showDie fields added to tracker wizard

### Phase 3: Sidebar + Section Architecture Redesign
**Status:** ✅ COMPLETE
**Goal:** Sidebar and main view always in sync (Google Docs TOC style).

Done:
- SECTION_REGISTRY maps English section IDs to {render, label, emoji, deletable, hiddenWhen}
- sectionHeader(sectionId, extra) builds <h2> with emoji from registry
- CHAR.sidebar is master layout controller (array of IDs + separator objects)
- renderSections() iterates CHAR.sidebar and calls registered renderers
- ensureSidebar() auto-adds missing built-in sections, removes stale entries
- resolveSidebarItem() resolves sidebar entry to full metadata
- Game Panel is a regular built-in section (`game-panel` in SECTION_REGISTRY), draggable/reorderable
- Game Panel has no section header (visually distinct card container)
- renderPanel() fills `<div id="game-panel">` placeholder, binds live listeners
- Sidebar drag-and-drop reorder in edit mode (drag handle + trash drop zone)
- moveSidebarItem() calls both renderSidebar() and renderSections() for sync
- Delete controls: built-in sections protected, separators delete instantly, custom features confirm + cascade
- addFeature() button wired in sidebar footer (edit mode)

### Phase 4: Pip Tracker Fix (Both Themes)
**Status:** ✅ COMPLETE
**Goal:** Filled = available, hollow = used. Clear in both themes.

Done:
- Light mode pip contrast fix (used pips clearly hollow, available slots solid-filled)
- --pip-off-bg and --pip-off-border variables added for light mode visibility
- Death save colors to CSS variables (--death-succ, --death-fail) in both themes
- Pip text color to CSS variable (--pip-text)
- Consistent treatment: all pip types (tracker, spell slot, HD, death save) use CSS variables

### Phase 5: Button Overflow & Panel Polish
**Status:** ✅ COMPLETE
**Goal:** No overflows, polished panel at all widths.

Done:
- Gold card: replaced 4 fixed buttons with custom amount input + −/+ buttons
- CSS class renamed oro-row → gold-row
- Hardcoded colors moved to CSS variables

### Phase 6: Algorithm/Wizard UX
**Status:** ✅ COMPLETE
**Goal:** Contextual labels, in-modal editing, usability first.

Done:
- Content block inline editor: editBlock/saveBlockEdit/cancelBlockEdit/cbeCollectFromDOM
- Paragraph, note, header, bullets block types have working inline editors
- cbeRenderTable() — table key-value pair editor implemented
- cbeRenderSubfeature() — subfeature editor implemented
- Feature wizard step 3: page-replacement UX for tracker/action editing
- Live preview in feature, spell, weapon, and algorithm wizards
- Hints converted to hover tooltips (title attribute + ⓘ icon)
- Tag system replaces isNew/isSecret/secretLabel
- Algo step inline editor with question, bullets, indent checkbox (no prompt())
- setAidBonus() replaced with inline input (zero prompt() calls remain)
- Subfeature content block tag editor (cbeRenderTagEditor)

### Phase 7: Feature + Tracker + Action Integration
**Status:** ✅ COMPLETE
**Goal:** Features are the single source of truth for trackers and actions.

Architecture:
- Features embed .trackers[] (array) and .actions[] (array) — **plural, not singular**
- Each tracker: { label?, emoji?, total, recovery, die?, showDie? }
- Each action:  { label?, emoji?, type, description }
- label/emoji are optional — default to parent feature's title/emoji when omitted
- A feature can have MULTIPLE trackers and MULTIPLE actions (e.g. subclass grants several)
- Session tracker IDs: slugify(t.label || f.title)
- **Standalone CHAR.trackers[] REMOVED** — replaced by equipment-based tracking
- Equipment items with `tracked: true` appear as pip trackers in game panel
- Equipment tracker IDs: `eq-` + slugify(e.name)
- CHAR.actions[] array REMOVED — all actions come from features
- Panel renders trackers by scanning features + tracked equipment items
- **Weapons auto-derive in equipment table** — no manual duplication needed

Done:
- Features embed plural trackers[]/actions[] arrays
- Feature wizard step 3 rewritten as list editor (add/edit/delete)
- Tracker/action editing uses page-replacement UX (replaces wizard body)
- editFeature() flattens trackers/actions for prefill
- Equipment wizard: optional tracker fields (tracked, quantity, emoji, recovery, isPotion, potionFormula)
- Equipment tracker pips rendered in game panel, respecting recovery on rest
- deleteEquip() cleans up SESSION tracker data
- Weapons auto-appear in equipment table (derived rows, edit/delete go through weapon wizard)
- syncSession, findTrackerById, longRest, tracker rendering updated for equipment-based trackers
- catalion.json updated: potions moved from trackers[] to equipment[], weapon duplicates removed

### Phase 8: Spell Preparation & Ritual
**Status:** ✅ COMPLETE
**Goal:** Class-aware spell preparation, ritual badge.

Prepared caster detection (auto-set from class):
- Daily preparation (show toggle): Cleric, Druid, Paladin, Ranger, Wizard
- Always prepared (no toggle): Bard, Sorcerer, Warlock

Done:
1. Added `prepared` (boolean) and `ritual` (boolean) to spell data model
2. Ritual checkbox in spell wizard step 1 (with hint tooltip)
3. Inline prepared toggle on spell cards (does NOT require edit mode)
4. Unprepared spells render dimmed (opacity .45, .7 on hover)
5. Ritual badge ("R Ritual") chip on spell cards and wizard preview
6. `preparedCaster` flag in spellcasting config (already existed)
7. Cantrips always treated as prepared (no toggle shown)
8. Prepared state preserved when editing spells via wizard
9. setAidBonus() replaced with inline input (last prompt() eliminated)

### Phase 9: Smart Auto-Calculations
**Status:** ✅ COMPLETE
**Goal:** PB, DC, attack bonus, weapon stats all auto-computed with override option.

Done:
- `proficiencyBonusOverride` field added to char-create wizard (Combat step), `flattenChar()`, and `onSave`. All 6 PB computation sites updated to check override first.
- Spell Save DC and Spell Attack Bonus overrides (`saveDCOverride`, `attackBonusOverride`) were already computed and displayed; added wizard fields in spellcasting wizard so users can now set them via UI. `onSave` updated (no longer blindly preserves old value).
- Weapon `attackBonusOverride` (number) and `damageOverride` (text) added to weapon wizard and `onSave`. `editWeapon()` already spreads full object so prefill works automatically.
- All override fields are optional: empty = auto-compute, non-empty = use override value.
- Backward compatible: new fields are additive, old saves without overrides work unchanged.

### Phase 10: 6-Step Character Creation
**Status:** ✅ COMPLETE
**Goal:** Comprehensive creation with spellcaster auto-detection.

Done:
- Added `DND.casterAbility` map: `{Bard:'CHA', Cleric:'WIS', Druid:'WIS', Paladin:'CHA', Ranger:'WIS', Sorcerer:'CHA', Warlock:'CHA', Wizard:'INT'}`.
- Added **Step 5: Skills** to char-create wizard using the same `_buildFields()` pattern as the standalone skills wizard. 18 dropdowns, same proficiency levels.
- Added **Step 6: Spellcasting (Optional)** — fields `sc_ability`, `sc_focus`, `sc_preparedCaster`. `_afterRender` hook auto-fills the ability dropdown based on `WIZ_DATA.class` + `DND.casterAbility`. Description note explains step is optional for non-casters.
- `onSave` updated: always writes skills from wizard data (both create and edit). Updates `CHAR.spellcasting` only if an ability was selected; preserves existing `saveDCOverride`/`attackBonusOverride`.
- `flattenChar()` updated: flattens `CHAR.skills` map to `sk_*` prefixed keys, adds `sc_*` prefixed spellcasting fields. Editing a character now correctly prefills all 6 steps.

### Phase 11: Smart Spell Slot Prompt
**Status:** ✅ COMPLETE
**Goal:** Toast with action button when adding spell at level with no slots.

Done:
- On new spell save (not edit), if level > 0 and no `CHAR.spellSlots` entry exists for that level, a deferred `info` toast appears with "＋ Add Slot" button that opens the spell slot wizard pre-filled to that level.
- Extended `showToast(msg, type, btn)` with optional `btn={label, fn}` argument that renders a `.toast-btn` inside the toast.
- Fixed pre-existing bug: `showToast` was setting class `toast toast-info` but CSS expected `.toast.info`. Fixed to `toast info`.
- Added `.toast-btn` CSS (border, cursor, inherit color).
- Added `toastNoSlot` and `toastAddSlot` i18n keys in BASE and TRANSLATIONS.it.

### Phase 12: Rest System Fix
**Status:** ✅ COMPLETE
**Goal:** Rests work per D&D 2024 rules.

Done:
- **longRest() bug fixed:** feature trackers with `recovery:'short'` were incorrectly excluded from long rest reset. Long rest now resets all non-manual trackers (both short and long recovery).
- **longRest() toast:** shows `🌙 Long rest — fully restored!` after completion.
- **shortRest() fully implemented:** resets `recovery:'short'` equipment and feature trackers, resets Pact Magic spell slots, opens HD spending dialog.
- **HD spending dialog:** replaces the rests card in the game panel when active. Shows available HD count + die type, −/+ quantity buttons, "Roll & Heal" button (rolls Nd_max + CON mod, heals HP, logs result, shows `+N HP` toast), and "Skip" button (shows skipped toast). Uses `SESSION.hdDialog` flag to trigger re-render.
- **Pact Magic spell slots:** `pactMagic` boolean flag added to spell slot wizard (checkbox). `onSave` saves the flag. `editSpellSlot()` prefills it. Pact Magic slots display their own label instead of "Lv N" in the spells section. Short rest resets pact magic slots; long rest resets all slots (as before).
- **syncSession():** backward compatible — existing saves without `hdDialog` default to `false` via `??` pattern.

### Phase 13: FAB (Floating Action Button)
**Status:** ✅ COMPLETE
- Floating `＋` button bottom-right, edit mode only. Rotates on open/close.
- Menu simplified to 4 items: Level Up, Add Feature, Add Item, Add Spell (only if spellcasting configured).
- `renderFAB()` called from `updateFixedControls()`. `closeFAB()` called by each item's onclick.

### Phase 14: Edit Mode Banner
**Status:** ✅ COMPLETE (scope reduced)
- Banner removed per user decision — orange inset glow (`body.edit-mode::after`) is sufficient visual feedback.

### Phase 15: Getting Started Card
**Status:** ✅ COMPLETE
- One-time card shown after new character creation (`SESSION.showGettingStarted=true` set in char-create `onSave`).
- Buttons: Add Weapon, Add Equipment, Add Feature, Add Spell / Set up Spellcasting.
- `gsAction(key)` enables edit mode + calls `renderAll()` before opening wizard.
- `dismissGettingStarted()` clears the flag. Rendered at top of `renderSections()`.

### Phase 16: Basic Level-Up Wizard (v1 limited)
**Status:** ✅ COMPLETE
- 2-step wizard: Step 1 = HP gain (number field + "Use average" checkbox, **checked by default**, auto-fills average value). Step 2 = preview checklist.
- `onSave`: increments `CHAR.level`, adds HP to `CHAR.hp.max` and `SESSION.hp.current`, stores `CHAR.levelUpChecklist` as `[{text, done:false}]`.
- Checklist lives in **`CHAR`** (not SESSION) so it survives reloads and JSON exports until manually dismissed.
- `buildLevelUpChecks(C, newLv, pbChanged, isCaster)` — shared helper used by wizard preview and `onSave`.
- Persistent checklist card rendered above sections. Items toggle individually; "All done" button dismisses.
- Triggered from FAB and ⬆️ button in base-data section header.
- `syncSession()` silently migrates old saves that stored checklist in `SESSION`.

### Phase 17: Session Cleanup
**Status:** ✅ COMPLETE
- `syncSession()` prunes stale `SESSION.trackers` entries for deleted features/equipment.
- `syncSession()` prunes stale `SESSION.spellSlots` entries for deleted slot levels.

### Phase 18: Portrait Size Cap
**Status:** ✅ COMPLETE
- `loadPortrait()` resizes via canvas to 512px max, encodes as JPEG quality 0.8.

### Phase 19: Import Validation
**Status:** ✅ COMPLETE
- `validateAndMigrateChar(c)` validates required fields (throws on missing name / invalid structure).
- Ensures all arrays are arrays, clamps level 1–20, defaults ability scores to 10, migrates legacy skills format.

### Phase 20: AI Assistant (`assistant.html`)
**Status:** ✅ COMPLETE

A standalone companion page that lets users ask D&D 2024 questions and apply character changes directly from a chat interface, with no manual JSON editing.

Architecture decisions:
- **JSON Patch (RFC 6902)** instead of full-JSON regeneration. AI always returns targeted ops; client applies them. Eliminates token bloat and truncation risk.
- **Prose-only chat display.** The patch block is never shown to the user. Chat shows only explanation + wizard instructions. A single "Apply changes" button appears when a valid patch is found.
- **Patch-failed hint.** If the AI attempted a `json-patch` block but it's malformed, a subtle `⚠` note in the user's language appears instead of the Apply button. The user follows wizard steps as fallback.
- **Auto-detect `json` blocks.** If the AI uses ` ```json` `` ` instead of ` ```json-patch` `` ` but the content is patch ops, it's silently treated the same way. Other `json` blocks are silently dropped (no data-loss risk).
- **Silent apply, stay in chat.** `applyPatch()` updates localStorage, re-syncs HISTORY[0] in-place with fresh character state (no history bloat), shows a toast. No redirect.
- **Portrait + logEntries stripping.** Stripped before sending to AI (token waste); merged back from in-memory CHAR on apply via `mergeSession()`.
- **No technical language in prose.** Style rule enforced in both `sys` and `sysShort`: AI never mentions array indices, JSON paths, or field names in explanation or wizard steps.
- **Dynamic free-model info.** Fetches `https://text.pollinations.ai/models` on load to display actual model name, description, and tier in the settings hint.

Done:
- `applyJsonPatch(obj, ops)` — pure RFC 6902 engine (add/remove/replace) with auto-create for missing intermediate paths on `add`
- `applyPatch(uid)` — applies ops, merges session fields, saves, re-syncs HISTORY[0], toasts
- `render(text)` — handles `json-patch` and `json` blocks, renders headings as bold, no raw JSON ever shown
- `fetchPollinationsLimits()` — live model info fetch with i18n fallbacks
- Full i18n of all UI strings in `assistant.html` (`applyBtn`, `applyToast`, `applyError`, `patchFailed`, `modelInfo`, `loadingModel`, etc.)
- System prompt (`sys` + `sysShort`) updated: always-output-patch contract, no-technical-language rule

### Phase 21: Passive Skills
**Status:** ✅ COMPLETE
**Goal:** Show passive Perception, Investigation, and Insight scores auto-computed from skill proficiency + WIS mod.

Done:
- Displayed in the Skills section below active skills.
- Auto-computed: `10 + WIS mod + (proficiency bonus if proficient, doubled if expertise)`.
- No wizard needed — pure derived values.

### Phase 22: Inspiration & Exhaustion
**Status:** ✅ COMPLETE
**Goal:** Track Bardic/Heroic Inspiration and Exhaustion level in the game panel.

Done:
- **Inspiration**: Toggle button in game panel. `SESSION.inspiration` boolean. No dice — player decides.
- **Exhaustion**: 0–6 level tracker in game panel. `SESSION.exhaustion` integer. Long rest reduces by 1 (per D&D 2024). Level 6 = dead. Each level shows penalty summary.

### Phase 23: Multi-Currency
**Status:** ✅ COMPLETE
**Goal:** Replace single "gold" field with full D&D 2024 currency (PP/GP/EP/SP/CP).

Done:
- `SESSION.currency = {pp, gp, ep, sp, cp}` replaces `SESSION.gold`.
- Game panel: 5 coin tiles in a horizontal row. Click a tile to select it; `−` / step input / `+` controls act on the selected coin.
- `selectCurTab(c)` does DOM-only updates (no re-render). `adjustCur(dir)` updates both game panel and equipment table instantly.
- Equipment table: read-only mirror of all 5 currencies.
- `syncSession()` migrates old `SESSION.gold` to `SESSION.currency.gp`.

### Phase 24: Spell Components (V/S/M)
**Status:** ✅ COMPLETE
**Goal:** Track verbal, somatic, and material components per spell; show material text when needed.

Done:
- `compV`, `compS`, `compM` (boolean) and `compMaterial` (string) fields added to spell data model.
- Checkboxes in spell wizard. `compMaterial` text field shown only when `compM` is checked (`_afterRender` hook).
- Component badges (V / S / M) rendered on spell cards. M badge shows tooltip with material text.
- `catalion.json` updated: all 11 spells filled with correct D&D 2024 components.

### Phase 25: Weapon Mastery (D&D 2024)
**Status:** ✅ COMPLETE
**Goal:** Each weapon can have one Mastery property (Cleave, Graze, Nick, Push, Sap, Slow, Topple, Vex).

Done:
- `mastery` field added to weapon data model.
- `DND.masteryProps` list and `DND.masteryDesc` (EN) + `DND.tr.it.masteryDesc` (IT) with accurate D&D 2024 descriptions.
- Select field in weapon wizard step 2.
- Mastery chip rendered on weapon cards with CSS `::after` tooltip showing the description.
- `catalion.json` updated: Pugnale→Nick, Spada Bella→Vex.

### Phase 26: Attunement
**Status:** ✅ COMPLETE
**Goal:** Mark equipment items as requiring attunement; show attuned count (max 3) in equipment section.

Done:
- `attuned` boolean field added to equipment data model.
- Checkbox in equipment wizard.
- Attunement chip shown inline on equipment table rows when attuned.
- Attunement count badge `N/3 attuned` shown in equipment section header when any items are attuned.

### Phase 27: Spell Filter Bar
**Status:** ✅ COMPLETE
**Goal:** Quick search/filter across spells without leaving the page.

Done:
- Sticky filter bar in Spells section: text search input + "Prepared" toggle button.
- `setSpellFilter(val)` / `clearSpellFilter()` update module-level filter state and re-render.
- Scroll position and input focus preserved on re-render (saves/restores `window.scrollY`, re-focuses input).
- Filtering is case-insensitive substring match on spell name, school, action type, and tags.

### Phase 28: Weapon & Armor Proficiencies
**Status:** ✅ COMPLETE
**Goal:** Store and display weapon/armor proficiency strings on the character sheet.

Done:
- `CHAR.weaponProficiencies` and `CHAR.armorProficiencies` free-text fields added to data model.
- Fields in char-create wizard (Combat step) and `flattenChar()`/`onSave` wired.
- Displayed in base-data section below language/tool proficiencies.

### Phase 29: Character Lore
**Status:** ✅ COMPLETE
**Goal:** Structured section for physical description, personality, backstory, and ideals/bonds/flaws.

Done:
- `CHAR.lore` object: `{age, height, weight, eyes, hair, skin, personalityTraits, ideals, bonds, flaws, backstory}`.
- Dedicated Lore section (`lore` in SECTION_REGISTRY) with its own `renderLore()` and wizard.
- Lore wizard: two steps (Physical / Personality & Backstory).
- `catalion.json` updated: full Italian backstory + physical stats for Catalion.

### Phase 30: Unarmed Strike
**Status:** ✅ COMPLETE
**Goal:** Auto-derive unarmed strike from STR mod and display it in weapons section.

Done:
- Unarmed strike auto-rendered as a derived row in the weapons table (not stored in `CHAR.weapons`).
- Damage: `1 + STR mod` (minimum 1) bludgeoning; attack bonus: `PB + STR mod`.
- Not editable — it's always auto-computed. Consistent with the override pattern.

### Phase 31: UI Redesign — Gold/Navy Palette
**Status:** ✅ COMPLETE
**Goal:** Replace blue/purple accent palette with a polished gold/navy palette for both themes.

Done:
- Dark theme: base `#0f0f1a`, accent `#c9a227` (gold), warm off-white text `#d8d8e8`.
- Light theme: base `#f5f0e8`, accent `#8a6800` (dark gold), warm cream tones.
- Header logo: `font-weight:800`, `letter-spacing:.04em`, gold text-shadow.
- Header bottom border: `2px solid var(--accent)` (structural divider signal).
- `h2` section headers: gold accent left-border (4px), uppercase, `letter-spacing:.02em`, `font-weight:700`.
- Active tab underline: reserved slot via `border-bottom:2px solid transparent` on inactive; `border-bottom-color:var(--accent)` on active. No tab layout shift.
- `.btn-primary`, `.add-btn`, assistant send button: gold gradients.
- `.ctrl-btn`: gold-tinted border + hover bg; `.ctrl-btn.active`: subtle gold bg.
- All changes mirrored identically in both `index.html` and `assistant.html`.
- New i18n keys: `overflowTheme`, `overflowLang` (EN + IT in both files).

### Phase 32: Mobile UX
**Status:** ✅ COMPLETE
**Goal:** Make theme/lang controls accessible on mobile; fix chat input hidden behind mobile browser chrome.

Done:
- **Overflow menu (`⋯` button):** On `≤768px`, `.hdr-right` hides and `#hdr-overflow-btn` appears. Dropdown shows theme and language toggles. Closes on outside click. Fully i18n'd. Implemented identically in both files.
- **Chat height fix (`assistant.html`):** `html,body{height:100dvh}`, `#ai-main{height:calc(100dvh - 50px)}` on mobile, `#ui{max-height:80px}`, reduced `.ibar` padding. Prevents send button and input from being hidden behind mobile browser chrome.

### Phase 33: UX Polish
**Status:** ✅ COMPLETE
**Goal:** Sidebar scroll anchoring, sidebar character block clickable, portrait lightbox.

Done:
- **Scroll anchor margin:** `scroll-margin-top:68px` on `h2`, `.spell-level-title`, and `#game-panel`. Sidebar nav links no longer land under the fixed header.
- **Sidebar char block:** `.sb-char-info` is now `cursor:pointer` with hover highlight; clicking smooth-scrolls to page top.
- **Portrait lightbox:** Clicking portrait when one exists opens full-screen `#portrait-lightbox` overlay. Supports scroll-wheel zoom (desktop) and pinch zoom (mobile). ESC key or clicking outside closes. "📷 Change photo" + "Close" buttons. If no portrait, clicking opens file picker directly.
- **Mastery tooltip z-index:** Raised from `100` to `210` so tooltip always renders above the fixed sidebar (`z-index:200`).

---



### Full Level-Up Wizard
- ASI step at levels 4, 8, 12, 16, 19: +/- on abilities (2 points)
- "Take a Feat" toggle -> feat database picker
- Auto-suggest class features based on class + level

### Class Feature Tables
- Priority classes: Bard, Monk, Barbarian, Paladin, Rogue, Wizard
- Data: CLASS_FEATURES[className][level] = [{name, description, type}]
- Source: http://dnd2024.wikidot.com/

### Feat Database
- All D&D 2024 feats (General, Origin, Fighting Style, Epic Boon)
- Searchable picker during ASI/feat choice

---

## v3.0 Data Model

### Target CHAR structure (no redundancy, engine is smart)

```
{
  name, quote, race, class, subclass, level, background, alignment,
  playerName, speed, ac, armorNote, hp: {max},
  hitDieType, initiativeBonus, languages, toolProficiencies,
  weaponProficiencies?, armorProficiencies?,  // free-text strings

  abilityScores: { STR, DEX, CON, INT, WIS, CHA },
  savingThrows: ["DEX", "CHA"],

  // Map format — absence = "none". Only non-none stored.
  skills: { acrobatics: "proficient", stealth: "expertise", ... },

  spellcasting: {
    ability: "CHA",           // auto-filled from class
    preparedCaster: false,     // auto-set from class
    focus: "...",
    dcOverride: null,          // null = auto-calc
    attackBonusOverride: null  // null = auto-calc
  },

  spellSlots: [{ level, total, pactMagic? }],

  spells: [{
    level, name, originalName, emoji, actionType, school,
    range, duration, concentration?, saveAbility?,
    description, scaling?, notes?,
    compV?, compS?, compM?,        // boolean component flags
    compMaterial?,                 // material component text (e.g. "a pinch of sand")
    prepared?, ritual?,
    tags?: [{ label, color }]  // 0-3 tags (green/blue/purple/red/orange)
  }],

  weapons: [{
    name, emoji, quantity,
    damageDie: "1d4",          // die only, no modifier
    damageType, attackStat,
    mastery?,                  // Cleave|Graze|Nick|Push|Sap|Slow|Topple|Vex
    magicBonus?,               // optional +1/+2/+3
    attackBonusOverride?,      // null = auto-calc
    damageOverride?,           // null = auto-calc
    properties?, notes?,
    tags?: [{ label, color }]
  }],

  equipment: [{
    name, notes?,
    // Optional tracker fields (e.g. potions, scrolls)
    tracked?, quantity?, emoji?,
    attuned?,                    // boolean — shows chip + counts toward 3-item limit
    recovery?,                   // manual/short/long
    isPotion?, potionFormula?
  }],

  features: [{
    title, emoji, source?,
    subtitle?,
    tags?: [{ label, color }],  // 0-3 tags (green/blue/purple/red/orange)
    contentBlocks: [{ type, text?, title?, emoji?, bullets?, rows?, ... }],
    // Embedded trackers (plural — a feature can have multiple)
    trackers?: [{ label?, emoji?, total, recovery, die?, showDie? }],
    // Embedded action cards (plural — a feature can have multiple)
    actions?: [{ label?, emoji?, type: "action"|"bonus"|"reaction", description }]
    // label/emoji default to parent feature's title/emoji when omitted
  }],

  customConditions: ["Aid attivo (+5 PF)"],

  combatAlgorithm: [{
    title, emoji?,
    steps: [{ question?, bullets: [], indent? }]
  }],

  // IDs only — labels/emojis derived from registry or features
  sidebar: ["game-panel", "base-data", {type:"sep"}, "skills", "spells", "weapons", ...]
}
```

### SESSION structure

```
{
  hp: { current, temp, aidBonus },
  hitDice: { used },
  trackers: {
    "slugified-feature-title": { used: 0 },  // feature trackers
    "eq-slugified-item-name": { used: 0 }     // equipment trackers
  },
  spellSlots: { "1": { used: 0 }, "2": { used: 0 } },
  currency: { pp, gp, ep, sp, cp },           // replaces old `gold` field
  inspiration: false,                          // boolean
  exhaustion: 0,                               // 0-6
  round, concentration, initiative,
  conditions: [],
  deathSucc, deathFail,
  notes, portrait, logEntries,
  showGettingStarted?
}
```

### Fields removed from the legacy model (pre-v3.0)
- proficiencyBonus -> computed from level (override: proficiencyBonusOverride)
- spellcasting.saveDC -> computed (override: dcOverride)
- spellcasting.attackBonus -> computed (override: attackBonusOverride)
- weapon.attackBonus / weapon.damage -> computed from damageDie+attackStat+magicBonus
- skills array of objects -> map format (name/ability from DND.standardSkills)
- sidebar {id,label,emoji} objects -> ID strings only
- CHAR.actions[] array -> embedded in features as .action
- feature+tracker duplication -> tracker embedded in feature
- CHAR.conditions (full list) -> CHAR.customConditions (custom only)
- CHAR.trackers[] standalone array -> equipment-based tracking (tracked flag on equipment items)
- tracker/action manual id fields -> auto-generated via slugify()
- empty/null fields -> omitted, engine handles defaults

---

## Design Decisions Log

| # | Decision | Choice |
|---|----------|--------|
| 1 | Default language | Italian (it) |
| 2 | Panel color scheme | Full theme consistency |
| 3 | Spell slot linking | Toast with action button |
| 4 | Empty state UX | Edit mode stays as gate |
| 5 | Content discovery | FAB in edit mode |
| 6 | Post-creation | Interactive getting started card, one-time |
| 7 | Sidebar population | Content-aware (only sections with content) |
| 8 | Sidebar architecture | TOC-style: sidebar order = view order |
| 9 | Sidebar separators | Simple lines, no labels |
| 10 | Section deletion | Only custom features deletable |
| 11 | Game panel position | Regular built-in section, draggable, first by default |
| 12 | Prompt dialogs | Replace with in-modal editing |
| 13 | Feature+tracker | Integrated final step in feature wizard |
| 14 | Feature+action | Embedded in features, CHAR.actions[] removed |
| 15 | Level-up (v1) | Basic: level+HP+checklist |
| 16 | Spell preparation | Inline toggle, class-aware |
| 17 | Gold buttons | Simplify to +/- only |
| 18 | Pip visual | Filled (available) vs hollow (used) |
| 19 | Spell DC/attack | Auto-calc with manual override |
| 20 | Weapon stats | Auto-calc with manual override |
| 21 | Spellcaster detection | Hardcoded class list, auto-fill ability |
| 22 | Char creation | 6-step wizard |
| 23 | Short rest | Full implementation (trackers + HD dialog) |
| 24 | Manual trackers | Never auto-reset on rest |
| 25 | Warlock pact magic | pactMagic flag on spell slots |
| 26 | Subclass casters | Manual via FAB |
| 27 | Getting started buttons | Auto-enable edit mode |
| 28 | Hit dice on short rest | Dialog with quantity buttons |
| 29 | Ritual casting | Flag + badge |
| 30 | Multiclass | Not in v1 (single class) |
| 31 | Tool/language prof | Free-text fields |
| 32 | Multiple characters | Single with JSON export |
| 33 | Content block types | Keep current 6 (generic enough) |
| 34 | Edit mode indicator | Banner + visual tint |
| 35 | Tracker rename | Auto-migrate SESSION data |
| 36 | Portrait cap | 512px max, JPEG 0.8 |
| 37 | Session cleanup | Auto-remove stale data |
| 38 | Section registry | Registry object pattern |
| 39 | Import validation | Validate + add defaults |
| 40 | Ability prof levels | None/Proficient/Expertise/JackOfAllTrades |
| 41 | Prepared caster list | Cleric/Druid/Paladin/Ranger/Wizard |
| 42 | Empty built-in sections | Always show with empty state |
| 43 | Hidden section recovery | Via FAB menu |
| 44 | Skills data model | Map format (id -> proficiency type) |
| 45 | Sidebar data model | ID-only array |
| 46 | Conditions data model | Custom-only (standard from DND.conditions) |
| 47 | Omit empty fields | Yes, engine handles defaults |
| 48 | Spell sidebar sub-links | Auto-generated per spell level |
| 49 | Backward compat | Required — app is deployed, users have saved JSON. New fields OK with defaults, never remove/rename existing fields. Migrate in syncSession()/ensureSidebar() if needed. |
| 50 | No redundancy | Auto-compute + override everywhere |
| 51 | v1.1 class tables | Bard, Monk, Barbarian, Paladin, Rogue, Wizard |
| 52 | English canonical D&D names | Stored in English, localized via dndTr() at display time |
| 53 | select-or-custom field type | Fixed list + "Custom..." option for homebrew in wizards |
| 54 | Feature trackers/actions | Arrays (plural) with per-entry label+emoji, not singular |
| 55 | Content block inline editing | Replace all prompt() with in-modal editing |
| 56 | Sidebar reorder | Drag-drop with trash zone + renderSections() sync |
| 57 | Tag system | tags:[{label,color}] replaces isNew/isSecret/secretLabel |
| 58 | Live wizard preview | Feature/spell/weapon/algo wizards show live preview at bottom |
| 59 | Field hints | Hover tooltips (title attr + ⓘ icon), not visible divs |
| 60 | Tracker/action editing | Page-replacement UX (replaces wiz-body, not inline row edit) |
| 61 | Character emoji | Removed (dead data — stored but never displayed) |
| 62 | Skill proficiency levels | none/proficient/expertise/halfProficiency (renamed from jackOfAllTrades) |
| 64 | Equipment tracking | Equipment items with `tracked:true` show as pip trackers in game panel |
| 65 | Standalone trackers | Removed — use equipment tracking or feature-embedded trackers instead |
| 66 | Weapons in equipment | Weapons auto-derive in equipment table (single source of truth, no duplication) |
| 67 | Game panel header | No section header (visually distinct card container) |
| 63 | Skills display | Always show all 18, non-proficient at 55% opacity |
| 68 | AI output format | JSON Patch RFC 6902 (not full JSON regeneration) |
| 69 | AI chat display | Prose + wizard steps only; patch block invisible; Apply button if valid |
| 70 | Patch failure UX | Subtle `⚠` hint in user language; no Apply button; user follows wizard steps |
| 71 | Legacy json blocks | Auto-detect patch ops → Apply button; other json silently dropped |
| 72 | Apply behavior | Silent in-chat apply; HISTORY[0] overwritten in-place; toast confirmation; no redirect |
| 73 | Portrait/logEntries | Stripped before AI send; merged back from in-memory CHAR on apply |
| 74 | AI technical language | Banned from prose/wizard steps (style rule 8); allowed only in patch block |
| 75 | Free model limits | Dynamic fetch from Pollinations /models API; shown in settings hint with i18n fallback |
| 76 | Patch omit rule | AI may omit patch only for pure rules questions; no "too complex" escape hatch |
| 77 | Multi-currency | PP/GP/EP/SP/CP replace single gold field; `SESSION.currency` map; old `SESSION.gold` migrated in syncSession() |
| 78 | Currency UI | Coin tile selector in game panel; adjustCur() updates both panel and equipment table without re-render |
| 79 | Passive skills | Displayed in Skills section; auto-computed (10 + ability mod + proficiency), never stored |
| 80 | Inspiration | Boolean in SESSION; toggle in game panel; no dice (player decides) |
| 81 | Exhaustion | 0–6 in SESSION; long rest reduces by 1 per D&D 2024; level 6 = dead |
| 82 | Spell components | compV/compS/compM booleans + compMaterial string on spells; V/S/M badges on cards |
| 83 | Material component display | M badge shows tooltip with material text; wizard shows compMaterial field only when compM is checked |
| 84 | Weapon mastery | mastery field on weapons; DND.masteryDesc (EN) + DND.tr.it.masteryDesc (IT); CSS ::after tooltip |
| 85 | Attunement | attuned boolean on equipment; chip on table rows; N/3 badge in section header |
| 86 | Spell filter | Sticky bar in Spells section; text search + prepared toggle; scroll/focus preserved on re-render |
| 87 | Weapon/armor proficiencies | Free-text fields in char-create wizard (Combat step); displayed in base-data section |
| 88 | Character lore | CHAR.lore object; dedicated section + wizard (Physical + Personality & Backstory steps) |
| 89 | Unarmed strike | Auto-derived row in weapons table; not stored; damage = 1+STR mod, attack = PB+STR mod |
| 90 | Schema version | Single source of truth: SCHEMA_VERSION = '3.0' in index.html; all exports and Catalion JSON use "3.0" |
| 91 | Accent palette | Gold/navy replaces blue/purple: dark `#c9a227`, light `#8a6800`; warm cream/grey backgrounds |
| 92 | Header height | 50px (up from 48px) for visual breathing room; all dependent offsets updated in both files |
| 93 | Header border | 2px solid var(--accent) — signals structural divider, not component border |
| 94 | Section h2 style | Gold accent left-border (4px), uppercase text, letter-spacing, font-weight:700 |
| 95 | Tab active underline | Reserved slot via border-bottom:2px solid transparent on inactive; no layout shift between pages |
| 96 | Mobile overflow menu | ⋯ button on ≤768px reveals theme/lang toggles in dropdown; implemented identically in both files |
| 97 | Mobile chat height | html,body{height:100dvh} in assistant.html prevents send button hidden behind mobile chrome |
| 98 | Scroll anchor margin | scroll-margin-top:68px on h2/.spell-level-title/#game-panel so sidebar links clear fixed header |
| 99 | Sidebar char block | .sb-char-info is clickable (smooth scroll to top) with hover highlight |
| 100 | Portrait lightbox | Click portrait → full-screen overlay; scroll/pinch zoom; ESC to close; no portrait → file picker |
| 101 | Mastery tooltip z-index | z-index:210 — above fixed sidebar (200), below modal (400+) |
| 102 | Aid HP mechanics | `setAidBonus()` grants/clamps `hp.current` by delta per D&D 2024; Aid raises both max AND current HP |
| 103 | AI weapons vs equipment | Explicit CRITICAL rule in both `getSys()` and `sysShort`: weapons (attack roll + damage dice) → `weapons[]`, never `equipment[]` |

---

## Known Bugs (Fix During Implementation)

| Bug | Location | Fix |
|-----|----------|-----|
| ~~Condition names not translated~~ | ~~toggleCond()~~ | ✅ Fixed (dndTr) |
| ~~"PF" hardcoded in logs~~ | ~~L1654, L1662~~ | ✅ Fixed (T('hpAbbr')) |
| ~~"Nessun dado vita" hardcoded~~ | ~~spendHD()~~ | ✅ Fixed (T() key) |
| ~~Tracker die/showDie not in wizard~~ | ~~WIZARDS.tracker~~ | ✅ Fixed |
| ~~Action ID is dead code~~ | ~~WIZARDS.action~~ | ✅ Fixed (removed) |
| ~~shortRest() is a no-op~~ | ~~shortRest()~~ | ✅ Fixed (Phase 12) |
| ~~longRest() ignores tracker recovery~~ | ~~longRest()~~ | ✅ Fixed (checks recovery field) |
| ~~Manual trackers reset on long rest~~ | ~~longRest()~~ | ✅ Fixed (skips recovery:'manual') |
| ~~PB auto-calc shadowed~~ | ~~renderBaseData~~ | ✅ Fixed (Phase 9 — override pattern) |
| ~~Death save colors hardcoded~~ | ~~CSS~~ | ✅ Fixed (--death-succ/--death-fail) |
| ~~Gold input color hardcoded~~ | ~~CSS~~ | ✅ Fixed (CSS variable) |
| ~~Pip text color hardcoded~~ | ~~CSS~~ | ✅ Fixed (--pip-text) |
| **~~Tracker label shows parent title~~** | ~~buildPanelRow2~~ | ✅ Fixed (trackers[] with label) |
| **~~Action label shows parent title~~** | ~~quick actions~~ | ✅ Fixed (actions[] with label) |
| **~~Only 1 tracker/action per feature~~** | ~~data model~~ | ✅ Fixed (trackers[]/actions[] arrays) |
| **~~cbeRenderTable() not defined~~** | ~~editBlock()~~ | ✅ Fixed |
| **~~cbeRenderSubfeature() not defined~~** | ~~editBlock()~~ | ✅ Fixed |
| **~~Sidebar reorder not wired~~** | ~~renderSidebar~~ | ✅ Fixed (drag-drop + trash zone) |
| **~~Algo step editor uses prompt()~~** | addAlgoStep | ✅ Fixed (inline editing) |
| **~~Content block preview blank on wizard open~~** | `renderWizardStep` | ✅ Fixed (`injectWizPreview()` at end of field-based path) |
| **~~Block summary shows "2" for table, blank for bullets~~** | `renderContentBlockEditor` | ✅ Fixed (synced template with `refreshCBEditor`) |
| **~~WIZ_BLOCKS shallow-spreads live CHAR blocks~~** | `openWizard` | ✅ Fixed (deep-clone via `JSON.parse(JSON.stringify(...))`) |
| **~~HP/Aid doesn't grant current HP~~** | `setAidBonus`, `buildPanel` | ✅ Fixed (`setAidBonus` grants/clamps `hp.current` by delta per D&D 2024; effMax formula fixed; level-up and char-edit caps updated) |
| **~~Action log wiped on every `renderPanel()` call~~** | `buildPanelBottom` | ✅ Fixed (`#log-wrap` populated from `SESSION.logEntries` during render) |
| **~~Double-save bug in `setAidBonus()`~~** | `setAidBonus` | ✅ Fixed (`saved` flag guard prevents `blur` re-entry from `updateHPDisplay()`) |
| **~~`dndTr()` returns raw key in English~~** | `dndTr` | ✅ Fixed (added `DND[cat]?.[key]` intermediate fallback before raw key) |
| **~~`profType_halfProficiency` translations swapped~~** | BASE / TRANSLATIONS.it | ✅ Fixed (EN/IT values corrected; `expertise` → "Maestria" in IT) |
| **~~Concentration input overflow on mobile~~** | CSS `#conc-spell-input` | ✅ Fixed (`flex:1; min-width:0`; removed inline `style="width:160px"`) |

---

## Key Line References (index.html)

> **Note:** Line numbers are approximate and shift frequently. Use grep/search
> to find components. These are kept as rough landmarks only.

| Component | ~Lines |
|-----------|--------|
| CSS theme variables (dark) | ~1-30 |
| CSS theme variables (light) | ~31-60 |
| HTML skeleton | ~490-520 |
| DND constants + canonical lists | ~750-900 |
| BASE i18n object | ~904-1280 |
| TRANSLATIONS.it object | ~1283-1650 |
| SCHEMA_VERSION + export helpers | ~1653-1750 |
| renderAll() + renderFAB() | ~1749-1812 |
| syncSession() | ~1691-1728 |
| SECTION_REGISTRY | ~1814-1830 |
| ensureSidebar() | ~1856-1940 |
| renderSidebar() | ~1943-2035 |
| renderPanel / buildPanelRow* | ~2035-2385 |
| renderSections() | ~2385-2412 |
| renderBaseData() | ~2412-2486 |
| renderSpellsSection() | ~2520-2621 |
| renderWeapons() | ~2621-2666 |
| renderEquipment() | ~2666-2711 |
| renderLore() | ~2720-2930 |
| longRest() / shortRest() | ~2933-2960 |
| addLog() / toast() | ~2738-2760 |
| renderField() / wizard engine | ~3195-3400 |
| WIZARDS config object | ~3934+ |
