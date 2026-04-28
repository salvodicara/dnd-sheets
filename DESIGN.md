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
**Status:** NOT STARTED
**Goal:** All source keys English, zero hardcoded Italian, proper translations everywhere.

Tasks:
1. Full audit of every addLog() call and rendered string for hardcoded Italian
2. Add ~80+ new keys to BASE (English) for all wizard labels
3. Add matching Italian translations to TRANSLATIONS.it
4. Convert every WIZARDS definition to use T()
5. Fix toggleCond(): use dndTr('conditions', name) for log messages
6. Add hpAbbr key (HP/PF), fix hardcoded "PF" in damage/heal logs (L1654, L1662)
7. Fix lvOpts() (L2135): translate 'Lv ' prefix
8. Fix spendHD() (L1679): hardcoded Italian error message
9. Remove dead i18n keys (editOn/editOff)
10. Use orphaned keys (noEquip, noFeatures, sidebarEmpty) in empty states

Key naming convention: camelCase, grouped by wizard prefix:
- wiz_charCreate_title, wiz_charCreate_step_identity, wiz_charCreate_f_name
- wiz_spell_title, wiz_spell_step_base, wiz_spell_f_nameIt

### Phase 2: Auto-Generate Technical IDs
**Status:** NOT STARTED
**Goal:** Users never see or type technical IDs.

Tasks:
1. Tracker wizard: remove id field. Auto-generate via slugify(label).
   Handle collisions (-2, -3). On rename, migrate SESSION key.
2. Action wizard: remove dead id field (never referenced).
3. Sidebar link wizard: remove id field (replaced by section picker).
4. Add die (text) and showDie (checkbox) fields to tracker wizard.

### Phase 3: Sidebar + Section Architecture Redesign
**Status:** NOT STARTED
**Goal:** Sidebar and main view always in sync (Google Docs TOC style).

Architecture:
- CHAR.sidebar is the master layout controller (array of IDs + separators)
- SECTION_REGISTRY maps section IDs to render functions
- renderSections() iterates CHAR.sidebar and calls registered renderers
- Game Panel pinned at top (not reorderable)
- Spells section auto-generates expandable sub-links per spell level

Section types:

| Section | Deletable | Reorderable | Visibility |
|---------|-----------|-------------|------------|
| Game Panel | No | No (pinned top) | Always |
| Base Data | No | Yes | Always |
| Skills | No | Yes | Always (empty state if no skills) |
| Spells | No | Yes | Hidden if no spellcasting |
| Weapons | No | Yes | Always (empty state) |
| Equipment | No | Yes | Always (empty state) |
| Algorithm | No | Yes | Hidden if empty |
| Custom features | Yes | Yes | Always when present |

Separators: simple visual lines (no labels).
Empty non-deletable sections always show with friendly empty-state and add button in edit mode.
Sidebar IDs only — labels/emojis derived from section registry or features at render time.

### Phase 4: Pip Tracker Fix (Both Themes)
**Status:** NOT STARTED
**Goal:** Filled = available, hollow = used. Clear in both themes.

Tasks:
1. New CSS vars: --pip-on, --pip-off-bg (transparent), --pip-off-border, --pip-text
2. Remove opacity:.5 hack. Hollow appearance for used pips.
3. Death save colors to CSS variables (--death-succ, --death-fail)
4. Spell slot pips: keep per-level colors, used = clearly hollow
5. Consistent treatment across all pip types

### Phase 5: Button Overflow & Panel Polish
**Status:** NOT STARTED
**Goal:** No overflows, polished panel at all widths.

Tasks:
1. Gold card: replace 4 buttons with +/− only
2. flex-wrap:wrap on .oro-row
3. Move hardcoded colors to CSS variables (gold #d4aa30, pip text #fff)
4. Audit all btn-row containers for overflow

### Phase 6: Algorithm/Wizard UX
**Status:** NOT STARTED
**Goal:** Contextual labels, in-modal editing, usability first.

Tasks:
1. Algo wizard step 1: "When do you use this?" with default emoji diamond
2. Algo wizard step 2: "Decision Steps" with descriptive intro
3. Replace prompt() in algo step editor with inline wizard fields
4. Replace prompt() in content block editor with inline wizard fields

### Phase 7: Feature + Tracker + Action Integration
**Status:** NOT STARTED
**Goal:** Features are the single source of truth for trackers and actions.

Architecture:
- Features optionally embed .tracker (total, recovery, die, showDie)
- Features optionally embed .action (type, description) for panel quick-ref cards
- CHAR.trackers[] only for standalone trackers (potions, generic resources)
- CHAR.actions[] array REMOVED — all actions come from features
- Panel renders trackers/actions by scanning features + standalone trackers

Feature wizard steps:
1. Header (title, emoji, subtitle, source, isNew, isSecret)
2. Content (inline content block editor)
3. Usage Tracking (optional: "Does this have limited uses?" -> tracker fields)
4. Quick Action (optional: "Show as action card in panel?" -> action type, description)

### Phase 8: Spell Preparation & Ritual
**Status:** NOT STARTED
**Goal:** Class-aware spell preparation, ritual badge.

Prepared caster detection (auto-set from class):
- Daily preparation (show toggle): Cleric, Druid, Paladin, Ranger, Wizard
- Always prepared (no toggle): Bard, Sorcerer, Warlock

Tasks:
1. Add prepared (boolean) and ritual (boolean) to spell data model
2. Inline toggle on spell cards (does NOT require edit mode)
3. Unprepared spells render dimmed but visible
4. Ritual badge ("R") on spell cards
5. preparedCaster flag in spellcasting config

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
- Always: Add Feature, Add Equipment, Add Weapon, Add Tracker, Add Algo Block
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
  playerName, emoji, speed, ac, armorNote, hp: {max},
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
    prepared?, ritual?, isNew?, isSecret?, secretLabel?
  }],

  weapons: [{
    name, emoji, quantity,
    damageDie: "1d4",          // die only, no modifier
    damageType, attackStat,
    magicBonus?,               // optional +1/+2/+3
    attackBonusOverride?,      // null = auto-calc
    damageOverride?,           // null = auto-calc
    properties?, notes?
  }],

  equipment: [{ name, notes? }],

  features: [{
    title, emoji, source?,
    subtitle?, isNew?, isSecret?, secretLabel?,
    contentBlocks: [{ type, text?, title?, emoji?, bullets?, rows?, ... }],
    // Optional embedded tracker
    tracker?: { total, recovery, die?, showDie? },
    // Optional embedded action card
    action?: { type: "action"|"bonus"|"reaction", description }
  }],

  // Standalone trackers only (not tied to features)
  trackers: [{
    label, emoji?, total, recovery,
    die?, showDie?,
    isPotion?, potionFormula?
    // id auto-generated from slugify(label)
  }],

  customConditions: ["Aid attivo (+5 PF)"],

  combatAlgorithm: [{
    title, emoji?,
    steps: [{ question?, bullets: [], indent? }]
  }],

  // IDs only — labels/emojis derived from registry or features
  sidebar: ["pannello", {type:"sep"}, "dati-base", "abilita", ...]
}
```

### SESSION structure

```
{
  hp: { current, temp, aidBonus },
  hitDice: { used },
  trackers: {
    "slugified-feature-title": { used: 0 },  // feature trackers
    "slugified-label": { used: 0 }            // standalone trackers
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
| 11 | Game panel position | Pinned at top always |
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

---

## Known Bugs (Fix During Implementation)

| Bug | Location | Fix |
|-----|----------|-----|
| Condition names not translated in logs | toggleCond() L1756-1757 | dndTr('conditions', name) |
| "PF" hardcoded in logs | L1654, L1662 | T('hpAbbr') |
| "Nessun dado vita" hardcoded | spendHD() L1679 | T() key |
| shortRest() is a no-op | L1785 | Full implementation |
| longRest() ignores tracker recovery | L1772-1783 | Check recovery field |
| Manual trackers reset on long rest | L1776-1778 | Skip recovery:'manual' |
| Tracker die/showDie not in wizard | WIZARDS.tracker | Add fields |
| Action ID is dead code | WIZARDS.action L2328 | Remove field |
| PB auto-calc shadowed | L1425, L1458 | Override pattern |
| noEquip/noFeatures unused | BASE keys | Use in empty states |
| Death save colors hardcoded | CSS L180-183 | CSS variables |
| Gold input color hardcoded | CSS L199 | CSS variable |
| Pip text color hardcoded | CSS L172 | CSS variable |

---

## Key Line References (character-sheet.html)

| Component | Lines |
|-----------|-------|
| CSS theme variables (dark) | 1-30 |
| CSS theme variables (light) | 31-60 |
| CSS pips | 169-183 |
| CSS gold row | 197-199 |
| HTML skeleton | 484-510 |
| DND constants | 576-611 |
| DND Italian translations | 614-641 |
| BASE i18n object | 653-775 |
| TRANSLATIONS.it object | 776-903 |
| T() function | 907 |
| EDIT_MODE global | 912 |
| computedPB() | 917 |
| syncSession() | 953-961 |
| renderAll() | 987-996 |
| getAvailableSections() | 1018-1034 |
| slugify() | 1013-1016 |
| renderSidebar() | 1122-1142 |
| renderPannello() / buildPannello() | 1162-1406 |
| renderSections() | 1408-1422 |
| renderDatiBase() | 1425-1455 |
| renderAbilita() | 1456-1478 |
| renderSpellsSection() | 1513-1574 |
| renderWeapons() | 1576-1594 |
| renderEquipment() | 1595-1608 |
| renderAlgorithm() | 1610-1623 |
| addLog() | 1626 |
| spendHD() | 1673-1690 |
| longRest() | 1772-1783 |
| shortRest() | 1785 |
| Wizard engine | 1848-1963 |
| Content block editor | 1964-2016 |
| Algo step editor | 2017-2050 |
| WIZARDS config object | 2137-2454 |
| loadPortrait() | 2611-2624 |
| toggleEditMode() | 2589-2594 |
