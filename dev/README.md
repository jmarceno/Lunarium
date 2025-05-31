# Game Content Manager

A Flask web application for managing game content for your First Person Dungeon Crawler game written in Lua with Love2D.

## Features

- **Visual Interface**: Modern, responsive web interface using Bootstrap and HTMX
- **Lua Integration**: Direct reading and writing of Lua table files
- **Multiple Data Types**: Support for items, skills, monsters, jobs, quests, and more
- **Form + JSON Editing**: Easy form interface for common fields, plus raw JSON editor for complex structures
- **Image Management**: Select sprites and images from your assets folder
- **Real-time Updates**: HTMX-powered interface for smooth user experience
- **Data Validation**: Built-in JSON validation and error handling

## Supported Data Types

- **Items** - Weapons, armor, consumables with stats and requirements
- **Skills** - Player and monster abilities with effects and damage calculations
- **Monsters** - Enemy definitions with stats, abilities, and behaviors
- **Jobs** - Character classes with attributes and skill trees
- **Quests** - Storylines, objectives, and reward systems
- **Monster Abilities** - Special attacks and abilities for monsters
- **Minion Abilities** - Companion and summon abilities
- **Smith Recipes** - Crafting recipes and material requirements
- **Unique Items** - Rare items with special properties
- **Set Items** - Equipment sets with matching themes
- **Set Bonuses** - Bonuses for wearing complete equipment sets

## Installation

1. **Install Python Dependencies**:
   ```bash
   cd dev
   pip install -r requirements.txt
   ```

2. **Install Lua Runtime** (if not already installed):
   ```bash
   # On Windows with Anaconda/Miniconda:
   conda install -c conda-forge lupa
   
   # Or with pip (may require compilation):
   pip install lupa
   ```

## Running the Application

1. **Start the Flask Development Server**:
   ```bash
   cd dev
   python app.py
   ```

2. **Open Your Browser**:
   Navigate to `http://localhost:5000`

## Usage

### Dashboard
- The main dashboard shows all available data types
- Click on any card to manage that type of content

### Managing Content
- **View All**: See all items in a sortable, filterable table
- **Add New**: Create new content with guided forms
- **Edit**: Modify existing content using forms or JSON editor
- **Delete**: Remove content with confirmation

### Editing Features

#### Form Editor
- Intuitive forms for common fields
- Type-specific fields for different data types
- Dropdown selections for enums and references
- Image/sprite selection from assets folder

#### JSON Editor
- Raw JSON editing for complex structures
- Syntax highlighting and validation
- Format and validate buttons
- Handles nested objects and arrays

#### Hybrid Approach
- Use forms for basic fields
- Use JSON editor for complex properties like:
  - Effect objects in skills
  - Ability arrays in monsters
  - Requirements and job restrictions
  - Level modifier functions

## File Structure

```
dev/
├── app.py              # Main Flask application
├── requirements.txt    # Python dependencies
├── templates/         
│   ├── base.html      # Base template with Bootstrap/HTMX
│   ├── index.html     # Dashboard
│   ├── manage.html    # Data type management
│   └── edit.html      # Item editing interface
└── README.md          # This file
```

## Data File Mapping

The application automatically maps to your existing Lua data files:

```
data/item_definitions.lua       → Items
data/skill_definitions.lua      → Skills  
data/monster_definitions.lua    → Monsters
data/job_definitions.lua        → Jobs
data/quest_definitions.lua      → Quests
data/monsterAbilities.lua       → Monster Abilities
data/minionAbilities.lua        → Minion Abilities
data/smithRecipes_definitions.lua → Smith Recipes
data/items/unique_items.lua     → Unique Items
data/items/set_items.lua        → Set Items
data/items/set_bonuses.lua      → Set Bonuses
```

## Features Detailed

### Lua Integration
- Uses `lupa` library for seamless Lua-Python integration
- Preserves Lua syntax and structure when saving
- Handles complex nested tables and arrays
- Maintains comments and formatting where possible

### Image Assets
- Automatically scans `assets/` folder for images
- Supports PNG, JPG, JPEG, GIF, BMP formats
- Live preview of selected images
- Organized by subdirectories

### Data Validation
- Required field validation
- Type checking (numbers, strings, booleans)
- JSON syntax validation
- Lua table structure preservation

### Performance
- Lazy loading of data files
- Efficient table operations
- Minimal memory footprint
- Fast file I/O

## Customization

### Adding New Data Types
1. Add entry to `DATA_FILES` dictionary in `app.py`
2. Create corresponding Lua file handling logic
3. Add type-specific form fields in `edit.html`
4. Update table display in `manage.html`

### Custom Form Fields
- Modify the `edit.html` template
- Add type-specific sections
- Update the `parse_form_data()` function for custom processing

### Styling
- Modify CSS in `base.html`
- Customize Bootstrap theme
- Add custom icons and colors

## Troubleshooting

### Lua Runtime Issues
If you encounter issues with the `lupa` library:
```bash
# Try installing from conda-forge
conda install -c conda-forge lupa

# Or install system dependencies for compilation
# Ubuntu/Debian:
sudo apt-get install liblua5.3-dev

# macOS:
brew install lua
```

### File Permissions
Ensure the web application has read/write access to:
- `data/` directory and all subdirectories
- `assets/` directory (for image browsing)

### Port Conflicts
If port 5000 is already in use:
```python
# Change in app.py:
app.run(debug=True, port=5001)  # Use different port
```

## Security Notes

- This tool is intended for **development use only**
- Do not expose to public networks without authentication
- Consider adding user authentication for production use
- Backup your data files before major editing sessions

## Contributing

When adding features:
1. Maintain backward compatibility with existing Lua files
2. Add appropriate error handling
3. Update templates for new functionality
4. Test with various data structures

## Game Integration

After making changes:
1. Restart your Love2D game to reload data files
2. Test new content in-game
3. Use version control to track changes
4. Consider automated testing for critical game balance

---

**Happy content creation! 🎮** 