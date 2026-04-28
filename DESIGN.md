# DESIGN.md — D&D Sheets v1 / v1.1 Design Document

> **This document is the source of truth for implementation.** Any AI agent picking up
> work on this project should read this file first, then CLAUDE.md.

## Status

- **v0 (Complete):** Core character sheet, wizard system, i18n skeleton, dark/light themes
- **v1 (In Progress):** UX overhaul, i18n completion, sidebar architecture, smart features
- **v1.1 (Scoped, Deferred):** Full level-up wizard, class feature tables, feat database

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
**Status:** NOT STARTED
**Goal:** PB, DC, attack bonus, weapon stats all auto-computed with override option.

Tasks:
1. PB: CHAR.proficiencyBonusOverride (optional). Rendering uses computedPB(level).
2. Spell DC: auto 8+PB+mod. Override: spellcasting.dcOverride.
3. Spell attack: auto PB+mod. Override: spellcasting.attackBonusOverride.
4. Weapons: store damageDie, attackStat, magicBonus. Compute attackBonus and damage.
   Overrides: attackBonusOverride, damageOverride per weapon.
5. Remove manual PB/DC/attack fields from wizards. Show computed values.
6. Weapon wizard shows preview of computed values before saving.

### Phase 10: 6-Step Character Creation
**Status:** NOT STARTED
**Goal:** Comprehensive creation with spellcaster auto-detection.

Spellcaster class mapping:
Bard->CHA, Cleric->WIS, Druid->WIS, Paladin->CHA,
Ranger->WIS, Sorcerer->CHA, Warlock->CHA, Wizard->INT

Steps:
1. Identity (name, race, class, subclass, level, alignment, background, player, emoji)
2. Ability Scores (point buy widget)
3. Combat (HP max, hit die, AC, speed, initiative bonus)
4. Saving Throws (6 checkboxes)
5. Skills (18 dropdowns with proficiency options)
6. Spellcasting (conditional — auto-fill ability, auto-calc DC/attack, focus field)

### Phase 11: Smart Spell Slot Prompt
**Status:** NOT STARTED
**Goal:** Toast with action button when adding spell at level with no slots.

### Phase 12: Rest System Fix
**Status:** NOT STARTED
**Goal:** Rests work per D&D 2024 rules.

Bugs to fix:
- shortRest() is a no-op (just logs)
- longRest() ignores tracker recovery field
- Manual trackers reset on long rest (shouldn't)

Tasks:
1. Short rest: reset recovery:'short' trackers, show HD spending dialog with quantity buttons
2. Long rest: only reset recovery:'long' and recovery:'short'. Never reset recovery:'manual'.
3. Pact Magic: add pactMagic flag to spell slots. Short rest resets pact magic slots.
4. Recovery summary toast for both rest types.

### Phase 13: FAB (Floating Action Button)
**Status:** NOT STARTED
**Goal:** Central content addition, edit mode only, context-aware.

Menu items:
- Always: Add Feature, Add Equipment, Add Weapon, Add Algo Block
- If spellcasting: Add Spell, Add Spell Slot
- If NOT: Set up Spellcasting
- If Algorithm hidden: Show Algorithm
- Sidebar: Add Section, Add Separator

### Phase 14: Edit Mode Banner
**Status:** NOT STARTED
**Goal:** Banner + visual tint when editing. "Done" button. FAB appears.

### Phase 15: Getting Started Card
**Status:** NOT STARTED
**Goal:** One-time interactive card after char creation. Quick-action buttons auto-enable edit mode.

### Phase 16: Basic Level-Up Wizard (v1 limited)
**Status:** NOT STARTED
**Goal:** Increment level, HP increase (roll or average), checklist reminders.

### Phase 17: Session Cleanup
**Status:** NOT STARTED
**Goal:** syncSession() removes stale tracker/slot SESSION entries.

### Phase 18: Portrait Size Cap
**Status:** NOT STARTED
**Goal:** Canvas resize to 512px max, JPEG 0.8 compression.

### Phase 19: Import Validation
**Status:** NOT STARTED
**Goal:** Validate imported JSON, add defaults for new fields.

---

## v1.1 Scope (Deferred)

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
    prepared?, ritual?,
    tags?: [{ label, color }]  // 0-3 tags (green/blue/purple/red/orange)
  }],

  weapons: [{
    name, emoji, quantity,
    damageDie: "1d4",          // die only, no modifier
    damageType, attackStat,
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
  gold, round, concentration, initiative,
  conditions: [],
  deathSucc, deathFail,
  notes, portrait, logEntries,
  showGettingStarted?
}
```

### Removed from v2.0 model
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
| 49 | Backward compat | Not required (v3 breaking changes OK) |
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

---

## Known Bugs (Fix During Implementation)

| Bug | Location | Fix |
|-----|----------|-----|
| ~~Condition names not translated~~ | ~~toggleCond()~~ | ✅ Fixed (dndTr) |
| ~~"PF" hardcoded in logs~~ | ~~L1654, L1662~~ | ✅ Fixed (T('hpAbbr')) |
| ~~"Nessun dado vita" hardcoded~~ | ~~spendHD()~~ | ✅ Fixed (T() key) |
| ~~Tracker die/showDie not in wizard~~ | ~~WIZARDS.tracker~~ | ✅ Fixed |
| ~~Action ID is dead code~~ | ~~WIZARDS.action~~ | ✅ Fixed (removed) |
| shortRest() is a no-op | shortRest() | Full implementation (Phase 12) |
| ~~longRest() ignores tracker recovery~~ | ~~longRest()~~ | ✅ Fixed (checks recovery field) |
| ~~Manual trackers reset on long rest~~ | ~~longRest()~~ | ✅ Fixed (skips recovery:'manual') |
| PB auto-calc shadowed | renderBaseData | Override pattern (Phase 9) |
| ~~Death save colors hardcoded~~ | ~~CSS~~ | ✅ Fixed (--death-succ/--death-fail) |
| ~~Gold input color hardcoded~~ | ~~CSS~~ | ✅ Fixed (CSS variable) |
| ~~Pip text color hardcoded~~ | ~~CSS~~ | ✅ Fixed (--pip-text) |
| **~~Tracker label shows parent title~~** | ~~buildPanelRow2~~ | ✅ Fixed (trackers[] with label) |
| **~~Action label shows parent title~~** | ~~quick actions~~ | ✅ Fixed (actions[] with label) |
| **~~Only 1 tracker/action per feature~~** | ~~data model~~ | ✅ Fixed (trackers[]/actions[] arrays) |
| **~~cbeRenderTable() not defined~~** | ~~editBlock()~~ | ✅ Fixed |
| **~~cbeRenderSubfeature() not defined~~** | ~~editBlock()~~ | ✅ Fixed |
| **~~Sidebar reorder not wired~~** | ~~renderSidebar~~ | ✅ Fixed (drag-drop + trash zone) |
| **Algo step editor uses prompt()** | addAlgoStep | ✅ Fixed (inline editing) |

---

## Key Line References (index.html)

> **Note:** Line numbers are approximate and shift frequently. Use grep/search
> to find components. These are kept as rough landmarks only.

| Component | ~Lines |
|-----------|--------|
| CSS theme variables (dark) | ~1-30 |
| CSS theme variables (light) | ~31-60 |
| HTML skeleton | ~490-520 |
| DND constants + canonical lists | ~580-660 |
| BASE i18n object | ~660-830 |
| TRANSLATIONS.it object | ~830-1080 |
| syncSession() | ~1185-1195 |
| SECTION_REGISTRY | ~1255-1270 |
| ensureSidebar() | ~1296-1330 |
| renderSidebar() | ~1358-1395 |
| renderPanel / buildPanelRow* | ~1420-1690 |
| renderSections() | ~1690-1715 |
| longRest() / shortRest() | ~2100-2125 |
| Wizard engine | ~2140-2320 |
| Content block editor | ~2326-2415 |
| Algo step editor | ~2416-2445 |
| WIZARDS config object | ~2450-2810 |
| Feature CRUD | ~2930-2970 |
