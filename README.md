# D&D Sheets

A zero-dependency, single-file digital character sheet for D&D 2024, built with vanilla HTML, CSS, and JavaScript.

Open `index.html` in any browser. No server, no build step, no internet required.

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
- **Custom Resource Trackers** -- feature-embedded (bardic inspiration, etc.) or equipment-based (potions, scrolls)
- **Potion Tracker** -- auto-heals on use via dice formula (configured in equipment wizard)
- **Concentration** -- toggle with visual indicator
- **Round & Initiative Counter**
- **Gold Tracker** -- custom amount input with +/- buttons
- **Condition Toggles** -- standard D&D conditions
- **Action Log** -- timestamped log of all actions (last 40 entries)
- **Quick Actions** -- auto-generated from feature-embedded actions
- **Rest Buttons** -- long/short rest with D&D 2024 recovery rules
- **Quick Notes** -- freeform session notes

### Character Data
- Ability scores with auto-computed modifiers
- Saving throws (proficiency toggle)
- 18 standard skills always visible, with proficiency/expertise/half-proficiency support

### Spellcasting
- Spellcasting info summary (class, ability, save DC, attack bonus)
- Spell cards grouped by level with metadata chips (school, casting time, range, etc.)
- Markdown-lite descriptions with scaling notes
- Custom color tags (up to 3 per spell)
- Concentration indicator per spell

### Combat
- Weapon stat cards with attack/damage formulas and custom tags
- Combat Algorithm -- decision-tree blocks for turn planning

### Equipment & Features
- Equipment table with optional quantity/usage tracking (pip trackers in game panel)
- Weapons auto-appear in equipment table (single source of truth, no duplication)
- Feature sections with recursive content blocks (paragraph, bullets, table, note, header, subfeature)
- Features can embed trackers and quick actions (rendered in the game panel)
- Custom color tags (up to 3 per feature)

### UI / UX
- Dark and light themes (CSS custom properties, eye-comfort palette)
- English / Italian language toggle (extensible i18n system)
- Edit mode -- togglable add/edit/delete controls throughout the sheet
- Responsive mobile layout (hamburger menu at 768px)
- Sidebar navigation with drag-and-drop section reordering (mouse and touch)
- Live wizard preview -- see how your feature/spell/weapon will look as you fill in fields
- Toast notifications for feedback
- Modal wizard system for all CRUD operations

### AI Assistant (`assistant.html`)
A companion chat page that connects to the character sheet via localStorage.

- Ask D&D 2024 rules questions or request character changes in plain language
- AI returns a plain-language explanation + step-by-step wizard instructions
- Changes are applied directly to the sheet via **JSON Patch (RFC 6902)** — no full JSON regeneration, no copy-pasting
- One-click **Apply changes** button; stays in chat after applying (no redirect)
- If the patch is malformed, a subtle hint guides the user to follow the wizard steps manually
- Portrait and session log are stripped before sending (token efficiency) and restored on apply
- Works with multiple AI providers: free (Pollinations, no account needed), Gemini, Groq, OpenRouter, OpenAI
- Dynamic model info for the free tier (fetched live from Pollinations API)
- **Document import** — attach a PDF, TXT, or DOCX character sheet via the paperclip button; with no extra text the AI reads it and builds a full importable character; with extra text the document is used as conversation context instead
- **Campaign query mode (📖)** — toggle button in the chat bar switches context from the character sheet to the loaded campaign chronicle; AI answers lore/story questions instead of character questions. Uses keyword-based section selection to fit the most relevant chronicle sections within the context budget. For free-tier (Pollinations), a structured AI-generated summary is cached and used alongside keyword snippets
- Fully bilingual (English / Italian)

## Project Structure

```
dnd-sheets/
  index.html       Main character sheet (~5,200 lines)
  assistant.html   AI assistant companion page (~1,430 lines)
  chronicles.html  Campaign chronicle reader/editor (~540 lines)
  CLAUDE.md        AI steering document (golden rules, architecture)
  DESIGN.md        Design decisions, phase plan, data model
  examples/        Example files (campaign.md, catalion JSON, PDF)
```

## Data Format

Characters are stored as JSON (v3.0 schema). Key design principles:
- **No redundancy** -- only unique, non-derivable data is stored
- **English canonical names** -- D&D terms stored in English, localized at display time
- **Auto-compute + override** -- derived values calculated by engine, with optional manual overrides

Top-level structure:

```json
{
  "version": "3.0",
  "character": {
    "name": "...",
    "class": "Fighter",
    "subclass": "Champion",
    "level": 3,
    "race": "Human",
    "background": "Soldier",
    "languages": "Common, Dwarvish",
    "weaponProficiencies": "Simple weapons, Martial weapons",
    "armorProficiencies": "All armor, Shields",
    "abilityScores": { "STR": 16, "DEX": 14, "CON": 13, "INT": 10, "WIS": 12, "CHA": 8 },
    "savingThrows": ["STR", "CON"],
    "skills": { "athletics": "proficient", "intimidation": "proficient" },
    "spellcasting": { "ability": "CHA", "focus": "...", "preparedMax": 6 },
    "spellSlots": [{ "level": 1, "total": 2 }],
    "spells": [{ "name": "...", "level": 0, "school": "Evocation", "tags": [] }],
    "weapons": [{ "name": "...", "damageDie": "1d8", "damageType": "Slashing", "mastery": "Cleave", "tags": [] }],
    "equipment": [{ "name": "...", "tracked": true, "quantity": 1, "emoji": "🧪", "isPotion": true, "potionFormula": "2d4+2" }],
    "features": [{
      "title": "...", "emoji": "...", "source": "Fighter",
      "contentBlocks": [],
      "trackers": [{ "total": 2, "recovery": "short" }],
      "actions": [{ "type": "action", "description": "..." }],
      "tags": [{ "label": "New", "color": "green" }]
    }],
    "lore": { "traits": "...", "ideals": "...", "bonds": "...", "flaws": "...", "backstory": "..." },
    "combatAlgorithm": [],
    "sidebar": ["game-panel", "base-data", "skills", "spells", "weapons", "equipment", "algorithm"]
  },
  "session": {
    "hp": { "current": 30, "temp": 0, "aidBonus": 0 },
    "hitDice": { "used": 0 },
    "trackers": {},
    "spellSlots": {},
    "currency": { "pp": 0, "gp": 50, "ep": 0, "sp": 0, "cp": 0 },
    "round": 1,
    "concentration": "",
    "initiative": "",
    "conditions": [],
    "deathSucc": 0, "deathFail": 0,
    "inspiration": false,
    "exhaustion": 0,
    "notes": "",
    "portrait": null,
    "logEntries": []
  }
}
```

## Persistence

All data is saved to `localStorage` under the key `dnd_sheet_v2`. Export to JSON file for backup or sharing between devices.

## License

Personal project. Not yet licensed for distribution.
