# D&D Sheets

A zero-dependency, single-file digital character sheet for D&D 2024, built with vanilla HTML, CSS, and JavaScript.

Open `character-sheet.html` in any browser. No server, no build step, no internet required.

## Features

### Character Management
- Create characters via a guided wizard (identity, ability scores, combat stats, saving throws)
- Import/export characters as JSON files (or copy to clipboard)
- Upload a portrait image (stored as base64)

### Game Panel (Session Tracker)
- **HP tracking** -- damage, heal, temp HP, Aid bonus, with a color-coded HP bar
- **Hit Dice** -- clickable pip UI for tracking usage
- **Death Saving Throws** -- success/failure pip toggles
- **Spell Slots** -- per-level pip trackers, color-coded (9 levels)
- **Custom Resource Trackers** -- bardic inspiration, sorcery points, etc.
- **Potion Tracker** -- auto-heals on use via dice formula
- **Concentration** -- toggle with visual indicator
- **Round & Initiative Counter**
- **Gold Tracker**
- **Condition Toggles** -- standard D&D conditions
- **Action Log** -- timestamped log of all actions (last 40 entries)
- **Quick Actions** -- auto-generated from spells/weapons, plus manual entries
- **Rest Buttons** -- long/short rest with proper D&D recovery rules
- **Quick Notes** -- freeform session notes

### Character Data
- Ability scores with auto-computed modifiers
- Saving throws (proficiency toggle)
- 18 standard skills with proficiency/expertise/Jack of All Trades support
- Custom skills

### Spellcasting
- Spellcasting info summary (class, ability, save DC, attack bonus)
- Spell cards grouped by level with metadata chips (school, casting time, range, etc.)
- Markdown-lite descriptions with scaling notes
- NEW and SECRET tags for recently added or hidden spells
- Concentration indicator per spell

### Combat
- Weapon stat cards with attack/damage formulas
- Combat Algorithm -- decision-tree blocks for turn planning

### Equipment & Features
- Equipment table with quantity and gold value tracking
- Feature sections with recursive content blocks (paragraph, bullets, table, note, header, subfeature)

### UI / UX
- Dark and light themes (CSS custom properties)
- English / Italian language toggle (extensible i18n system)
- Edit mode -- togglable add/edit/delete controls throughout the sheet
- Responsive mobile layout (hamburger menu at 768px)
- Sidebar navigation with drag-and-drop section reordering
- Toast notifications for feedback
- Modal wizard system for all CRUD operations

## Project Structure

```
dnd-sheets/
  character-sheet.html          Main application (single file)
  Catalion/
    catalion.json               Example character data (v2.0 format)
    catalion_di_sancaldo_*.json Exported session snapshot
    Catalion_Livello3.html      Legacy v1 prototype (deprecated)
    *.pdf                       Traditional PDF character sheet
```

## Data Format

Characters are stored as JSON (v2.0 schema). The top-level structure:

```json
{
  "version": "2.0",
  "character": {
    "nome": "...",
    "classe": "...",
    "livello": 3,
    "razza": "...",
    "abilities": { "FOR": 10, "DES": 14, ... },
    "savingThrows": [...],
    "skills": [...],
    "spellcasting": {...},
    "spellSlots": [...],
    "spells": [...],
    "weapons": [...],
    "equipment": [...],
    "features": [...],
    "trackers": [...],
    "conditions": [...],
    "actions": [...],
    "combatAlgorithm": [...],
    "sidebar": [...]
  },
  "session": {
    "hp": 30, "maxHp": 30, "tempHp": 0,
    "hitDiceUsed": 0, "deathSuccess": 0, "deathFail": 0,
    "slotsUsed": [], "trackersUsed": [],
    "gold": 50, "round": 0, "initiative": 0,
    "concentration": false, "conditions": [],
    "log": [], "note": "", "portrait": null
  }
}
```

## Persistence

All data is saved to `localStorage` under the key `dnd_sheet_v2`. Export to JSON file for backup or sharing between devices.

## License

Personal project. Not yet licensed for distribution.
