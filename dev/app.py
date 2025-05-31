from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, send_from_directory
import os
import re
import json
from pathlib import Path
import lupa
from lupa import LuaRuntime

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'

# Get the project root (parent of dev folder)
PROJECT_ROOT = Path(__file__).parent.parent
DATA_PATH = PROJECT_ROOT / 'data'
ASSETS_PATH = PROJECT_ROOT / 'assets'

class LuaTableManager:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        
    def read_lua_file(self, file_path):
        """Read and parse a Lua file containing table definitions."""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Create a fresh Lua runtime for each file to avoid conflicts
            lua = LuaRuntime(unpack_returned_tuples=True)
            
            # Execute the Lua code
            result = lua.execute(content)
            
            # Check if the file returns a table directly
            if result is not None:
                converted = self._lua_to_python(result)
                print(f"Successfully loaded returned table from {file_path}")
                return converted if converted is not None else {}
            
            # Try to extract the main table (most files export one main table)
            table_name = self._extract_table_name(content)
            if table_name and table_name in lua.globals():
                result = self._lua_to_python(lua.globals()[table_name])
                print(f"Successfully loaded {table_name} from {file_path}")
                return result if result is not None else {}
            else:
                # If no main table found, return all globals that look like tables
                result = {}
                for key, value in lua.globals().items():
                    if not key.startswith('_') and hasattr(value, 'items'):
                        try:
                            result[key] = self._lua_to_python(value)
                        except Exception as e:
                            print(f"Error converting {key}: {e}")
                            continue
                print(f"Loaded globals from {file_path}: {list(result.keys())}")
                return result
                
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            import traceback
            traceback.print_exc()
            return {}
    
    def _extract_table_name(self, content):
        """Extract the main table name from Lua file content."""
        # Look for patterns like "local tableName = {" or "tableName = {"
        patterns = [
            r'local\s+(\w+)\s*=\s*{',
            r'(\w+Definitions)\s*=\s*{',
            r'return\s+(\w+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, content)
            if match:
                return match.group(1)
        
        return None
    
    def _lua_to_python(self, lua_obj):
        """Convert Lua objects to Python objects recursively."""
        if lua_obj is None:
            return None
        elif isinstance(lua_obj, (str, int, float, bool)):
            return lua_obj
        elif hasattr(lua_obj, 'items'):  # Lua table with key-value pairs
            result = {}
            try:
                for key, value in lua_obj.items():
                    result[key] = self._lua_to_python(value)
                return result
            except Exception as e:
                print(f"Error iterating table items: {e}")
                return {}
        else:
            # Try to handle as array/list, but be more careful
            try:
                # Check if it's actually iterable before trying to iterate
                iter(lua_obj)
                return [self._lua_to_python(item) for item in lua_obj]
            except (TypeError, AttributeError):
                # If it's not iterable, convert to string representation
                try:
                    return str(lua_obj)
                except Exception:
                    return None
    
    def write_lua_file(self, file_path, data, table_name):
        """Write Python data back to a Lua file."""
        print(f"DEBUG write_lua_file: Writing {table_name} to {file_path}")
        
        # Check if this is a complex table structure (like item_definitions.lua)
        if isinstance(data, dict) and ('items' in data or 'monsters' in data):
            # This is a complex structure that should be returned directly
            lua_content = self._python_to_lua_complex(data)
        else:
            # Simple table structure
            lua_content = self._python_to_lua(data, table_name)
        
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(lua_content)
            print(f"DEBUG write_lua_file: Successfully wrote to file")
        except Exception as e:
            print(f"DEBUG write_lua_file: Error writing to file: {e}")
            raise
    
    def _python_to_lua_complex(self, data):
        """Convert complex Python data structures to Lua format with return statement."""
        lines = []
        
        # Handle RARITY constant if present
        if 'RARITY' in data:
            lines.append("-- Define item rarities")
            lines.append("local RARITY = {")
            for key, value in data['RARITY'].items():
                lines.append(f'    {key} = "{value}",')
            lines.append("}")
            lines.append("")
        
        # Handle items table
        if 'items' in data:
            lines.append("local itemDefinitions = {")
            for key, value in data['items'].items():
                lines.append(f"    {key} = {self._format_value(value, 1)},")
            lines.append("}")
            lines.append("")
        
        # Handle monsterParts table
        if 'monsterParts' in data:
            lines.append("local monsterParts = {")
            for key, value in data['monsterParts'].items():
                lines.append(f"    {key} = {self._format_value(value, 1)},")
            lines.append("}")
            lines.append("")
        
        # Handle monsters table
        if 'monsters' in data:
            lines.append("local monsterDefinitions = {}")
            lines.append("monsterDefinitions.monsters = {")
            for key, value in data['monsters'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append("return monsterDefinitions")
            return "\n".join(lines)
        
        # Handle minion abilities table
        if 'definitions' in data:
            lines.append("local minionAbilities = {}")
            lines.append("minionAbilities.definitions = {")
            for key, value in data['definitions'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append("return minionAbilities")
            return "\n".join(lines)
        
        # Return the appropriate structure
        return_parts = []
        if 'items' in data:
            return_parts.append("items = itemDefinitions")
        if 'monsterParts' in data:
            return_parts.append("monsterParts = monsterParts")
        if 'RARITY' in data:
            return_parts.append("RARITY = RARITY")
            
        if return_parts:
            lines.append("return {")
            for part in return_parts:
                lines.append(f"    {part},")
            lines.append("}")
        
        return "\n".join(lines)
    
    def _python_to_lua(self, data, table_name, indent=0):
        """Convert Python data to Lua table format."""
        if isinstance(data, list):
            # Handle arrays (like quests and smith recipes)
            lines = []
            if indent == 0:
                lines.append(f"local {table_name} = {{")
            else:
                lines.append("{")
            
            for i, item in enumerate(data):
                indent_str = "    " * (indent + 1)
                lines.append(f"{indent_str}[{i + 1}] = {self._format_value(item, indent + 1)},")
            
            if indent == 0:
                lines.append("}")
                lines.append(f"\nreturn {table_name}")
            else:
                lines.append("    " * indent + "}")
            
            return "\n".join(lines)
        elif isinstance(data, dict):
            lines = []
            if indent == 0:
                lines.append(f"local {table_name} = {{")
            else:
                lines.append("{")
            
            for key, value in data.items():
                indent_str = "    " * (indent + 1)
                if isinstance(key, str) and key.isidentifier():
                    key_str = key
                else:
                    key_str = f'["{key}"]'
                
                if isinstance(value, dict):
                    lines.append(f"{indent_str}{key_str} = {{")
                    for sub_key, sub_value in value.items():
                        sub_indent_str = "    " * (indent + 2)
                        if isinstance(sub_key, str) and sub_key.isidentifier():
                            sub_key_str = sub_key
                        else:
                            sub_key_str = f'["{sub_key}"]'
                        lines.append(f"{sub_indent_str}{sub_key_str} = {self._format_value(sub_value, indent + 2)},")
                    lines.append(f"{indent_str}}},")
                else:
                    lines.append(f"{indent_str}{key_str} = {self._format_value(value, indent + 1)},")
            
            if indent == 0:
                lines.append("}")
                lines.append(f"\nreturn {table_name}")
            else:
                lines.append("    " * indent + "}")
            
            return "\n".join(lines)
        else:
            return self._format_value(data, indent)
    
    def _format_value(self, value, indent):
        """Format a single value for Lua output."""
        if isinstance(value, str):
            return f'"{value}"'
        elif isinstance(value, bool):
            return "true" if value else "false"
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, list):
            if not value:
                return "{}"
            # For arrays, use 1-based indexing like Lua
            lines = ["{"]
            for i, item in enumerate(value):
                indent_str = "    " * (indent + 1)
                lines.append(f"{indent_str}[{i + 1}] = {self._format_value(item, indent + 1)},")
            lines.append("    " * indent + "}")
            return "\n".join(lines)
        elif isinstance(value, dict):
            if not value:
                return "{}"
            lines = ["{"]
            for k, v in value.items():
                indent_str = "    " * (indent + 1)
                key_str = k if isinstance(k, str) and k.isidentifier() else f'["{k}"]'
                lines.append(f"{indent_str}{key_str} = {self._format_value(v, indent + 1)},")
            lines.append("    " * indent + "}")
            return "\n".join(lines)
        elif value is None:
            return "nil"
        else:
            return f'"{str(value)}"'

# Initialize the Lua table manager
lua_manager = LuaTableManager()

# Data file configurations
DATA_FILES = {
    'items': {
        'file': 'item_definitions.lua',
        'table_name': 'itemDefinitions',
        'display_name': 'Items'
    },
    'skills': {
        'file': 'skill_definitions.lua', 
        'table_name': 'skillDefinitions',
        'display_name': 'Skills'
    },
    'monsters': {
        'file': 'monster_definitions.lua',
        'table_name': 'monsterDefinitions',
        'display_name': 'Monsters'
    },
    'jobs': {
        'file': 'job_definitions.lua',
        'table_name': 'jobDefinitions', 
        'display_name': 'Jobs'
    },
    'quests': {
        'file': 'quest_definitions.lua',
        'table_name': 'questDefinitions',
        'display_name': 'Quests'
    },
    'monster_abilities': {
        'file': 'monsterAbilities.lua',
        'table_name': 'monsterAbilities',
        'display_name': 'Monster Abilities'
    },
    'minion_abilities': {
        'file': 'minionAbilities.lua', 
        'table_name': 'minionAbilities',
        'display_name': 'Minion Abilities'
    },
    'smith_recipes': {
        'file': 'smithRecipes_definitions.lua',
        'table_name': 'smithRecipes',
        'display_name': 'Smith Recipes'
    },
    'unique_items': {
        'file': 'items/unique_items.lua',
        'table_name': 'uniqueItems',
        'display_name': 'Unique Items'
    },
    'set_items': {
        'file': 'items/set_items.lua',
        'table_name': 'setItems', 
        'display_name': 'Set Items'
    },
    'set_bonuses': {
        'file': 'items/set_bonuses.lua',
        'table_name': 'setBonuses',
        'display_name': 'Set Bonuses'
    }
}

def get_image_files():
    """Get list of available image files from assets directory."""
    image_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp'}
    images = []
    
    if ASSETS_PATH.exists():
        for root, dirs, files in os.walk(ASSETS_PATH):
            for file in files:
                if Path(file).suffix.lower() in image_extensions:
                    rel_path = os.path.relpath(os.path.join(root, file), ASSETS_PATH)
                    images.append(rel_path.replace('\\', '/'))
    
    return sorted(images)

def get_skills_list():
    """Get list of all available skills from skill definitions."""
    skills_file = DATA_PATH / 'skill_definitions.lua'
    if skills_file.exists():
        skills_data = lua_manager.read_lua_file(skills_file)
        if skills_data:
            return sorted(list(skills_data.keys()))
    return []

def get_jobs_list():
    """Get list of all available jobs."""
    jobs_file = DATA_PATH / 'job_definitions.lua'
    if jobs_file.exists():
        jobs_data = lua_manager.read_lua_file(jobs_file)
        if jobs_data:
            return list(jobs_data.keys())
    return []

def get_damage_types():
    """Get list of damage types from damageTypes.lua"""
    damage_types_file = PROJECT_ROOT / 'gameplay' / 'damageTypes.lua'
    if damage_types_file.exists():
        damage_types_data = lua_manager.read_lua_file(damage_types_file)
        if damage_types_data and 'types' in damage_types_data:
            return sorted(list(damage_types_data['types'].keys()))
    return []

def get_monster_abilities():
    """Get list of all available monster abilities."""
    abilities_file = DATA_PATH / 'monsterAbilities.lua'
    if abilities_file.exists():
        abilities_data = lua_manager.read_lua_file(abilities_file)
        if abilities_data and 'definitions' in abilities_data:
            return sorted(list(abilities_data['definitions'].keys()))
    return []

def get_missing_skills_for_job(job_data):
    """Get list of skills referenced in job but not defined in skill_definitions.lua"""
    defined_skills = set(get_skills_list())
    missing_skills = set()
    
    # Check starting skills
    if 'startingSkills' in job_data:
        job_starting_skills = job_data['startingSkills']
        if isinstance(job_starting_skills, dict):
            # Handle Lua array as dict
            for skill in job_starting_skills.values():
                if skill not in defined_skills:
                    missing_skills.add(skill)
        elif isinstance(job_starting_skills, list):
            for skill in job_starting_skills:
                if skill not in defined_skills:
                    missing_skills.add(skill)
    
    # Check available skills  
    if 'availableSkills' in job_data:
        job_available_skills = job_data['availableSkills']
        if isinstance(job_available_skills, dict):
            # Handle Lua array as dict
            for skill in job_available_skills.values():
                if skill not in defined_skills:
                    missing_skills.add(skill)
        elif isinstance(job_available_skills, list):
            for skill in job_available_skills:
                if skill not in defined_skills:
                    missing_skills.add(skill)
    
    return sorted(list(missing_skills))

def get_items_list():
    """Get list of all available items."""
    items_file = DATA_PATH / 'item_definitions.lua'
    if items_file.exists():
        items_data = lua_manager.read_lua_file(items_file)
        if items_data and 'items' in items_data:
            return list(items_data['items'].keys())
    return []

# Character attributes from character.lua
CHARACTER_ATTRIBUTES = ["STR", "INT", "CON", "WIL", "CHA", "DEX", "WIS"]

# Equipment slots from item.lua 
EQUIPMENT_SLOTS = ["weapon", "offhand", "head", "body", "amulet", "ring"]

@app.route('/')
def index():
    """Main dashboard showing all available data types."""
    return render_template('index.html', data_files=DATA_FILES)

@app.route('/manage/<data_type>')
def manage_data(data_type):
    """Show management interface for a specific data type."""
    if data_type not in DATA_FILES:
        flash(f"Unknown data type: {data_type}")
        return redirect(url_for('index'))
    
    config = DATA_FILES[data_type]
    file_path = DATA_PATH / config['file']
    
    if not file_path.exists():
        flash(f"Data file not found: {config['file']}")
        return redirect(url_for('index'))
    
    # Load the data
    data = lua_manager.read_lua_file(file_path)
    
    # Ensure data is never None, always a dict
    if data is None:
        data = {}
    
    # Handle nested data structures for different file types
    if data_type == 'monsters' and 'monsters' in data:
        data = data['monsters']
    elif data_type == 'items' and 'items' in data:
        # Handle the items nested structure from item_definitions.lua
        data = data['items']
    elif data_type == 'minion_abilities' and 'definitions' in data:
        # Handle the minion abilities nested structure
        data = data['definitions']
    elif data_type == 'monster_abilities' and 'definitions' in data:
        # Handle the monster abilities nested structure
        data = data['definitions']
    elif data_type in ['quests', 'smith_recipes']:
        # Handle array-based data structures - convert to dict for easier management
        if isinstance(data, list):
            # Convert array to dict using ID field
            id_field = 'id' if data_type == 'quests' else 'name'
            data_dict = {}
            for item in data:
                if id_field in item:
                    data_dict[item[id_field]] = item
            data = data_dict
        elif isinstance(data, dict) and len(data) > 0:
            # Check if it's a Lua array (numeric keys starting from 1)
            first_key = next(iter(data.keys()))
            if isinstance(first_key, (int, str)) and str(first_key).isdigit():
                # Convert Lua array to dict using ID field
                id_field = 'id' if data_type == 'quests' else 'name'
                data_dict = {}
                for item in data.values():
                    if isinstance(item, dict) and id_field in item:
                        data_dict[item[id_field]] = item
                data = data_dict
    
    # Ensure data is still a dict after nested access
    if data is None:
        data = {}
    
    images = get_image_files()
    
    # Get additional data for specific types
    extra_data = {}
    if data_type == 'jobs':
        extra_data['skills'] = get_skills_list()
        extra_data['items'] = get_items_list()
        extra_data['jobs'] = get_jobs_list()
        extra_data['attributes'] = CHARACTER_ATTRIBUTES
        extra_data['equipment_slots'] = EQUIPMENT_SLOTS
    elif data_type == 'monsters':
        extra_data['damage_types'] = get_damage_types()
        extra_data['monster_abilities'] = get_monster_abilities()
    elif data_type == 'monster_abilities':
        extra_data['damage_types'] = get_damage_types()
    
    return render_template('manage.html', 
                         data_type=data_type,
                         config=config,
                         data=data,
                         images=images,
                         extra_data=extra_data)

@app.route('/edit/<data_type>/<item_id>')
def edit_item(data_type, item_id):
    """Edit a specific item."""
    if data_type not in DATA_FILES:
        flash(f"Unknown data type: {data_type}")
        return redirect(url_for('index'))
    
    config = DATA_FILES[data_type]
    file_path = DATA_PATH / config['file']
    
    # Load the data
    data = lua_manager.read_lua_file(file_path)
    
    # Ensure data is never None, always a dict
    if data is None:
        data = {}
    
    # Handle nested data structures for different file types
    if data_type == 'monsters' and 'monsters' in data:
        data = data['monsters']
    elif data_type == 'items' and 'items' in data:
        data = data['items']
    elif data_type == 'minion_abilities' and 'definitions' in data:
        # Handle the minion abilities nested structure
        data = data['definitions']
    elif data_type == 'monster_abilities' and 'definitions' in data:
        # Handle the monster abilities nested structure
        data = data['definitions']
    elif data_type in ['quests', 'smith_recipes']:
        # Handle array-based data structures - convert to dict for easier management
        if isinstance(data, list):
            # Convert array to dict using ID field
            id_field = 'id' if data_type == 'quests' else 'name'
            data_dict = {}
            for item in data:
                if id_field in item:
                    data_dict[item[id_field]] = item
            data = data_dict
        elif isinstance(data, dict) and len(data) > 0:
            # Check if it's a Lua array (numeric keys starting from 1)
            first_key = next(iter(data.keys()))
            if isinstance(first_key, (int, str)) and str(first_key).isdigit():
                # Convert Lua array to dict using ID field
                id_field = 'id' if data_type == 'quests' else 'name'
                data_dict = {}
                for item in data.values():
                    if isinstance(item, dict) and id_field in item:
                        data_dict[item[id_field]] = item
                data = data_dict
    
    # Ensure data is still a dict after nested access
    if data is None:
        data = {}
    
    if item_id not in data:
        flash(f"Item not found: {item_id}")
        return redirect(url_for('manage_data', data_type=data_type))
    
    item_data = data[item_id]
    images = get_image_files()
    
    # Get additional data for specific types
    extra_data = {}
    if data_type == 'jobs':
        extra_data['skills'] = get_skills_list()
        extra_data['items'] = get_items_list()
        extra_data['jobs'] = get_jobs_list()
        extra_data['attributes'] = CHARACTER_ATTRIBUTES
        extra_data['equipment_slots'] = EQUIPMENT_SLOTS
        
        # Check for missing skills in this specific job
        extra_data['missing_skills'] = get_missing_skills_for_job(item_data)
    elif data_type == 'monsters':
        extra_data['damage_types'] = get_damage_types()
        extra_data['monster_abilities'] = get_monster_abilities()
    elif data_type == 'monster_abilities':
        extra_data['damage_types'] = get_damage_types()
    
    # Special handling for set bonuses to prepare data for template
    if data_type == 'set_bonuses':
        # Prepare bonus data for display (excluding 'type' from JSON textareas)
        prepared_item_data = {}
        for piece_count, bonus_data in item_data.items():
            prepared_bonus = bonus_data.copy()
            prepared_item_data[piece_count] = prepared_bonus
        item_data = prepared_item_data
    
    # Special handling for unique items and set items to convert jobs dict to list
    elif data_type in ['unique_items', 'set_items', 'items']:
        if 'jobs' in item_data and isinstance(item_data['jobs'], dict):
            # Convert dict with numeric keys to list of job names
            jobs_list = []
            # Sort by key to maintain order
            for key in sorted(item_data['jobs'].keys()):
                if isinstance(key, (int, str)) and str(key).isdigit():
                    jobs_list.append(item_data['jobs'][key])
            item_data['jobs'] = jobs_list
    
    return render_template('edit.html',
                         data_type=data_type,
                         item_id=item_id,
                         item_data=item_data,
                         config=config,
                         images=images,
                         extra_data=extra_data)

@app.route('/new/<data_type>')
def new_item(data_type):
    """Create a new item."""
    if data_type not in DATA_FILES:
        flash(f"Unknown data type: {data_type}")
        return redirect(url_for('index'))
    
    config = DATA_FILES[data_type]
    images = get_image_files()
    
    # Provide template based on data type
    templates = {
        'items': {
            'name': '',
            'description': '',
            'type': 'weapon',
            'slot': 'weapon',
            'value': 0
        },
        'skills': {
            'name': '',
            'description': '',
            'type': 'physical',
            'target': 'single_enemy',
            'mpCost': 0,
            'basePower': 100
        },
        'monsters': {
            'id': '',
            'name': '',
            'stats': {
                'level': 1,
                'hp': 10,
                'attack': 5,
                'defense': 2,
                'speed': 5
            }
        },
        'jobs': {
            'tier': 1,
            'attributeModifiers': {},
            'availableSkills': [],
            'startingSkills': [],
            'startingEquipment': {},
            'requirements': {}
        },
        'quests': {
            'id': '',
            'name': '',
            'description': '',
            'type': 'KILL',
            'level': 1,
            'difficulty': 1,
            'giver': 'Guild',
            'objective': {
                'type': 'kill',
                'targetId': '',
                'targetName': '',
                'count': 5,
                'current': 0
            },
            'rewards': {
                'gold': 50,
                'items': []
            },
            'status': 'available',
            'seed': 12345
        },
        'smith_recipes': {
            'name': '',
            'description': '',
            'result': '',
            'materials': {},
            'goldCost': 50,
            'category': 'Weapons'
        }
    }
    
    item_data = templates.get(data_type, {})
    
    # Get additional data for specific types
    extra_data = {}
    if data_type == 'jobs':
        extra_data['skills'] = get_skills_list()
        extra_data['items'] = get_items_list()
        extra_data['jobs'] = get_jobs_list()
        extra_data['attributes'] = CHARACTER_ATTRIBUTES
        extra_data['equipment_slots'] = EQUIPMENT_SLOTS
    elif data_type == 'monsters':
        extra_data['damage_types'] = get_damage_types()
        extra_data['monster_abilities'] = get_monster_abilities()
    elif data_type == 'monster_abilities':
        extra_data['damage_types'] = get_damage_types()
    
    return render_template('edit.html',
                         data_type=data_type,
                         item_id='',
                         item_data=item_data,
                         config=config,
                         images=images,
                         is_new=True,
                         extra_data=extra_data)

@app.route('/save/<data_type>', methods=['POST'])
def save_item(data_type):
    """Save an item (new or existing)."""
    if data_type not in DATA_FILES:
        return jsonify({'error': f'Unknown data type: {data_type}'}), 400
    
    config = DATA_FILES[data_type]
    file_path = DATA_PATH / config['file']
    
    # Get form data
    form_data = request.form.to_dict()
    item_id = form_data.pop('item_id', '')
    original_id = form_data.pop('original_id', '')
    json_data = form_data.pop('json_data', None)
    
    # DEBUG: Key information for troubleshooting
    print(f"DEBUG: Saving {data_type}, item_id: {item_id}")
    
    if not item_id:
        flash('Item ID is required')
        return redirect(url_for('new_item', data_type=data_type))
    
    print(f"DEBUG: Item ID: {item_id}, Original ID: {original_id}")
    
    # If we have JSON data, use that; otherwise parse form data
    if json_data:
        try:
            # Parse the JSON data to see if it's different from original
            json_item_data = json.loads(json_data)
            
            # Always prefer form data over JSON for regular editing
            # JSON should only be used if form data is incomplete or for advanced fields
            if data_type == 'jobs':
                item_data = parse_job_form_data(form_data)
            elif data_type == 'monsters':
                item_data = parse_monster_form_data(form_data)
            elif data_type == 'quests':
                item_data = parse_quest_form_data(form_data)
            elif data_type == 'smith_recipes':
                item_data = parse_smith_recipe_form_data(form_data)
            elif data_type == 'unique_items':
                item_data = parse_unique_item_form_data(form_data)
            elif data_type == 'set_items':
                item_data = parse_set_item_form_data(form_data)
            elif data_type == 'set_bonuses':
                item_data = parse_set_bonuses_form_data(form_data)
            elif data_type == 'items':
                item_data = parse_item_form_data(form_data)
            else:
                item_data = parse_form_data(form_data)
            
            # Merge any advanced fields from JSON that aren't in form data
            for key, value in json_item_data.items():
                if key not in item_data:
                    item_data[key] = value
                    
        except json.JSONDecodeError as e:
            flash(f'Invalid JSON data: {e}')
            return redirect(url_for('edit_item', data_type=data_type, item_id=item_id) if not original_id else url_for('new_item', data_type=data_type))
    else:
        # Convert form data to proper types
        if data_type == 'jobs':
            item_data = parse_job_form_data(form_data)
        elif data_type == 'monsters':
            item_data = parse_monster_form_data(form_data)
        elif data_type == 'quests':
            item_data = parse_quest_form_data(form_data)
        elif data_type == 'smith_recipes':
            item_data = parse_smith_recipe_form_data(form_data)
        elif data_type == 'unique_items':
            item_data = parse_unique_item_form_data(form_data)
        elif data_type == 'set_items':
            item_data = parse_set_item_form_data(form_data)
        elif data_type == 'set_bonuses':
            item_data = parse_set_bonuses_form_data(form_data)
        elif data_type == 'items':
            item_data = parse_item_form_data(form_data)
        else:
            item_data = parse_form_data(form_data)
    
    print(f"DEBUG: Parsed item data: {item_data}")
    
    try:
        # Load existing data
        all_data = lua_manager.read_lua_file(file_path)
        # DEBUG: Essential info for troubleshooting
        print(f"DEBUG: Loaded data with keys: {list(all_data.keys()) if isinstance(all_data, dict) else type(all_data)}")
        
        # Ensure we have a valid data structure
        if all_data is None:
            all_data = {}
        
        # Handle nested structures
        if data_type == 'monsters':
            if 'monsters' not in all_data:
                all_data['monsters'] = {}
            data_section = all_data['monsters']
        elif data_type == 'items':
            if 'items' not in all_data:
                all_data['items'] = {}
            data_section = all_data['items']
        elif data_type == 'minion_abilities':
            if 'definitions' not in all_data:
                all_data['definitions'] = {}
            data_section = all_data['definitions']
        elif data_type == 'monster_abilities':
            if 'definitions' not in all_data:
                all_data['definitions'] = {}
            data_section = all_data['definitions']
        elif data_type in ['quests', 'smith_recipes']:
            # Handle array-based data structures
            if isinstance(all_data, list):
                # Convert existing array to dict for manipulation
                id_field = 'id' if data_type == 'quests' else 'name'
                data_dict = {}
                for item in all_data:
                    if id_field in item:
                        data_dict[item[id_field]] = item
                data_section = data_dict
            elif isinstance(all_data, dict) and len(all_data) > 0:
                # Check if it's a Lua array (numeric keys)
                first_key = next(iter(all_data.keys()))
                if isinstance(first_key, (int, str)) and str(first_key).isdigit():
                    # Convert Lua array to dict
                    id_field = 'id' if data_type == 'quests' else 'name'
                    data_dict = {}
                    for item in all_data.values():
                        if isinstance(item, dict) and id_field in item:
                            data_dict[item[id_field]] = item
                    data_section = data_dict
                else:
                    data_section = all_data
            else:
                # Empty or invalid structure, create new dict
                data_section = {}
        else:
            data_section = all_data
        
        # Handle ID changes for existing items
        if original_id and original_id != item_id and original_id in data_section:
            del data_section[original_id]
        
        # Ensure the item has the correct ID field
        if data_type == 'quests':
            item_data['id'] = item_id
        elif data_type == 'smith_recipes':
            item_data['name'] = item_id
        
        # Save the item
        data_section[item_id] = item_data
        print(f"DEBUG: Successfully added/updated {item_id}")
        
        # Convert back to array format for quest and smith recipe data
        if data_type in ['quests', 'smith_recipes']:
            all_data = list(data_section.values())
        elif data_type in ['monsters', 'items', 'minion_abilities', 'monster_abilities']:
            # For nested structures, we need to put the modified data_section back into all_data
            if data_type == 'monsters':
                all_data['monsters'] = data_section
            elif data_type == 'items':
                all_data['items'] = data_section
            elif data_type in ['minion_abilities', 'monster_abilities']:
                all_data['definitions'] = data_section
        else:
            # For simple structures, data_section is the complete data
            all_data = data_section
        
        # Write back to file
        lua_manager.write_lua_file(file_path, all_data, config['table_name'])
        
        print(f"DEBUG: File write completed successfully")
        
        flash(f'Successfully saved {item_id}')
        return redirect(url_for('manage_data', data_type=data_type))
        
    except Exception as e:
        print(f"DEBUG: Error during save: {e}")
        import traceback
        traceback.print_exc()
        flash(f'Error saving item: {e}')
        return redirect(url_for('edit_item', data_type=data_type, item_id=item_id) if not original_id else url_for('new_item', data_type=data_type))

@app.route('/delete/<data_type>/<item_id>', methods=['POST'])
def delete_item(data_type, item_id):
    """Delete an item."""
    if data_type not in DATA_FILES:
        return jsonify({'error': f'Unknown data type: {data_type}'}), 400
    
    config = DATA_FILES[data_type]
    file_path = DATA_PATH / config['file']
    
    # Load existing data
    all_data = lua_manager.read_lua_file(file_path)
    
    # Handle nested structures
    if data_type == 'monsters':
        if 'monsters' in all_data and item_id in all_data['monsters']:
            del all_data['monsters'][item_id]
        else:
            return jsonify({'error': 'Item not found'}), 404
    elif data_type == 'items':
        if 'items' in all_data and item_id in all_data['items']:
            del all_data['items'][item_id]
        else:
            return jsonify({'error': 'Item not found'}), 404
    elif data_type == 'minion_abilities' and 'definitions' in all_data:
        # Handle the minion abilities nested structure
        if 'definitions' in all_data and item_id in all_data['definitions']:
            del all_data['definitions'][item_id]
        else:
            return jsonify({'error': 'Item not found'}), 404
    elif data_type == 'monster_abilities' and 'definitions' in all_data:
        # Handle the monster abilities nested structure
        if 'definitions' in all_data and item_id in all_data['definitions']:
            del all_data['definitions'][item_id]
        else:
            return jsonify({'error': 'Item not found'}), 404
    elif data_type in ['quests', 'smith_recipes']:
        # Handle array-based data structures
        found = False
        if isinstance(all_data, list):
            # Find and remove from array
            id_field = 'id' if data_type == 'quests' else 'name'
            for i, item in enumerate(all_data):
                if item.get(id_field) == item_id:
                    del all_data[i]
                    found = True
                    break
        elif isinstance(all_data, dict) and len(all_data) > 0:
            # Check if it's a Lua array (numeric keys)
            first_key = next(iter(all_data.keys()))
            if isinstance(first_key, (int, str)) and str(first_key).isdigit():
                # Convert to dict, delete, then convert back to array
                id_field = 'id' if data_type == 'quests' else 'name'
                data_dict = {}
                for item in all_data.values():
                    if isinstance(item, dict) and id_field in item:
                        data_dict[item[id_field]] = item
                
                if item_id in data_dict:
                    del data_dict[item_id]
                    all_data = list(data_dict.values())
                    found = True
            else:
                # Regular dict structure
                if item_id in all_data:
                    del all_data[item_id]
                    found = True
        
        if not found:
            return jsonify({'error': 'Item not found'}), 404
    else:
        if item_id in all_data:
            del all_data[item_id]
        else:
            return jsonify({'error': 'Item not found'}), 404
    
    # Write back to file
    lua_manager.write_lua_file(file_path, all_data, config['table_name'])
    
    return jsonify({'success': True})

def parse_form_data(form_data):
    """Parse form data and convert to appropriate Python types."""
    result = {}
    
    for key, value in form_data.items():
        # Handle nested keys (e.g., "stats.hp", "effect.duration")
        if '.' in key:
            parts = key.split('.')
            current = result
            for part in parts[:-1]:
                if part not in current:
                    current[part] = {}
                current = current[part]
            current[parts[-1]] = convert_value(value)
        else:
            result[key] = convert_value(value)
    
    return result

def parse_monster_form_data(form_data):
    """Parse monster-specific form data with special handling for abilities, immunities, and resistances."""
    result = parse_form_data(form_data)
    
    # Handle abilities with chance values
    abilities = []
    total_chance = 0
    ability_chances = {}
    
    # First pass: collect all abilities and their chances
    for key, value in form_data.items():
        if key.startswith('abilities.') and key.endswith('.chance'):
            ability_id = key.split('.')[1]
            chance = convert_value(value) or 0
            if chance > 0:
                ability_chances[ability_id] = chance
                total_chance += chance
    
    # Normalize chances to sum to 1.0 if needed
    if total_chance > 0:
        for ability_id, chance in ability_chances.items():
            normalized_chance = chance / total_chance
            abilities.append({
                'id': ability_id,
                'chanceToUse': normalized_chance
            })
    
    if abilities:
        result['abilities'] = abilities
    
    # Handle immunities (checkboxes)
    immunities = []
    for key, value in form_data.items():
        if key.startswith('immunities.') and value:
            damage_type = key.split('.')[1]
            immunities.append(damage_type)
    if immunities:
        result['immunities'] = immunities
    
    # Handle resistances (damage type + value)
    resistances = {}
    for key, value in form_data.items():
        if key.startswith('resistances.') and value:
            damage_type = key.split('.')[1]
            resistance_value = convert_value(value)
            if resistance_value and resistance_value != 0:
                resistances[damage_type] = resistance_value
    if resistances:
        result['resistances'] = resistances
    
    return result

def parse_job_form_data(form_data):
    """Parse job-specific form data with special handling for complex fields."""
    result = parse_form_data(form_data)
    
    # Handle attribute modifiers
    attribute_modifiers = {}
    for attr in CHARACTER_ATTRIBUTES:
        field_name = f"attributeModifiers.{attr}"
        if field_name in form_data:
            value = convert_value(form_data[field_name])
            if value and value != 0:  # Only save non-zero values
                attribute_modifiers[attr] = value
    
    if attribute_modifiers:
        result['attributeModifiers'] = attribute_modifiers
    
    # Handle available skills (multiselect)
    available_skills = []
    for key, value in form_data.items():
        if key.startswith('availableSkills.') and value:
            available_skills.append(value)
    if available_skills:
        result['availableSkills'] = available_skills
    
    # Handle starting skills (multiselect)
    starting_skills = []
    for key, value in form_data.items():
        if key.startswith('startingSkills.') and value:
            starting_skills.append(value)
    if starting_skills:
        result['startingSkills'] = starting_skills
    
    # Handle starting equipment
    starting_equipment = {}
    for slot in EQUIPMENT_SLOTS:
        field_name = f"startingEquipment.{slot}"
        if field_name in form_data:
            value = form_data[field_name]
            if value and value != "none":  # Only save non-"none" values
                starting_equipment[slot] = value
    
    if starting_equipment:
        result['startingEquipment'] = starting_equipment
    
    # Handle requirements
    requirements = {}
    for key, value in form_data.items():
        if key.startswith('requirements.') and value:
            job_name = key.split('.')[1]
            requirements[job_name] = convert_value(value)
    if requirements:
        result['requirements'] = requirements
    
    return result

def parse_quest_form_data(form_data):
    """Parse quest-specific form data with special handling for objective and rewards fields."""
    result = parse_form_data(form_data)
    
    # Handle objective structure
    objective = {}
    for key, value in form_data.items():
        if key.startswith('objective.'):
            field_name = key.split('.')[1]
            converted_value = convert_value(value)
            if converted_value is not None and converted_value != '':
                objective[field_name] = converted_value
    
    if objective:
        result['objective'] = objective
    
    # Handle rewards structure  
    rewards = {}
    for key, value in form_data.items():
        if key.startswith('rewards.'):
            field_name = key.split('.')[1]
            converted_value = convert_value(value)
            if converted_value is not None and converted_value != '':
                rewards[field_name] = converted_value
    
    # Initialize empty items array if not present
    if 'rewards' not in result or 'items' not in result.get('rewards', {}):
        if 'gold' in rewards or 'reputation' in rewards:
            rewards['items'] = []
    
    if rewards:
        result['rewards'] = rewards
    
    return result

def parse_smith_recipe_form_data(form_data):
    """Parse smith recipe-specific form data with special handling for materials."""
    result = parse_form_data(form_data)
    
    # Handle materials (key-value pairs)
    materials = {}
    material_indices = set()
    
    # First, collect all material indices
    for key in form_data.keys():
        if key.startswith('materials.') and '.' in key:
            parts = key.split('.')
            if len(parts) >= 3:
                material_indices.add(parts[1])
    
    # Process each material
    for index in material_indices:
        name_key = f"materials.{index}.name"
        count_key = f"materials.{index}.count"
        
        material_name = form_data.get(name_key, '').strip()
        material_count = convert_value(form_data.get(count_key, ''))
        
        if material_name and material_count and material_count > 0:
            materials[material_name] = material_count
    
    if materials:
        result['materials'] = materials
    
    return result

def parse_item_form_data(form_data):
    """Parse regular item form data with special handling for jobs array."""
    result = parse_form_data(form_data)
    
    # Handle jobs array - collect job names from form fields
    jobs = []
    job_indices = []
    
    # First, collect all job indices
    for key in form_data.keys():
        if key.startswith('jobs.'):
            try:
                index = int(key.split('.')[1])
                job_indices.append(index)
            except (IndexError, ValueError):
                continue
    
    # Sort indices to maintain order, then collect job names
    for index in sorted(job_indices):
        job_name = form_data.get(f'jobs.{index}', '').strip()
        if job_name:  # Only add non-empty job names
            jobs.append(job_name)
    
    # Convert jobs array to numeric string key format to match existing structure
    if jobs:
        jobs_dict = {}
        for i, job_name in enumerate(jobs):
            jobs_dict[str(i + 1)] = job_name
        result['jobs'] = jobs_dict
    
    return result

def parse_unique_item_form_data(form_data):
    """Parse unique item-specific form data with special handling for requirements, jobs, and unique effects."""
    result = parse_form_data(form_data)
    
    # Handle requirements (attribute requirements)
    requirements = {}
    for key, value in form_data.items():
        if key.startswith('requirements.'):
            attr_name = key.split('.')[1]
            converted_value = convert_value(value)
            if converted_value and converted_value > 0:
                requirements[attr_name] = converted_value
    
    if requirements:
        result['requirements'] = requirements
    
    # Handle jobs array - collect job names from form fields
    jobs = []
    job_indices = []
    
    # First, collect all job indices
    for key in form_data.keys():
        if key.startswith('jobs.'):
            try:
                index = int(key.split('.')[1])
                job_indices.append(index)
            except (IndexError, ValueError):
                continue
    
    # Sort indices to maintain order, then collect job names
    for index in sorted(job_indices):
        job_name = form_data.get(f'jobs.{index}', '').strip()
        if job_name:  # Only add non-empty job names
            jobs.append(job_name)
    
    # Convert jobs array to numeric string key format to match existing structure
    if jobs:
        jobs_dict = {}
        for i, job_name in enumerate(jobs):
            jobs_dict[str(i + 1)] = job_name
        result['jobs'] = jobs_dict
    
    # Handle unique effects
    unique_effects = []
    effect_indices = set()
    
    # Collect all effect indices
    for key in form_data.keys():
        if key.startswith('uniqueEffects.'):
            parts = key.split('.')
            if len(parts) >= 3:
                effect_indices.add(parts[1])
    
    # Process each effect
    for index in effect_indices:
        effect_id = form_data.get(f"uniqueEffects.{index}.id", '').strip()
        effect_type = form_data.get(f"uniqueEffects.{index}.type", '')
        effect_data = form_data.get(f"uniqueEffects.{index}.effectData", '')
        
        if effect_id and effect_type:
            effect = {
                'id': effect_id,
                'type': effect_type
            }
            
            # Parse effect data as JSON
            if effect_data:
                try:
                    effect['effect'] = json.loads(effect_data)
                except json.JSONDecodeError:
                    # If JSON parsing fails, skip this effect
                    continue
            
            unique_effects.append(effect)
    
    if unique_effects:
        result['uniqueEffects'] = unique_effects
    
    # Set unique flag
    result['unique'] = True
    
    return result

def parse_set_item_form_data(form_data):
    """Parse set item-specific form data with special handling for requirements, jobs, and set properties."""
    result = parse_form_data(form_data)
    
    # Handle requirements (attribute requirements)
    requirements = {}
    for key, value in form_data.items():
        if key.startswith('requirements.'):
            attr_name = key.split('.')[1]
            converted_value = convert_value(value)
            if converted_value and converted_value > 0:
                requirements[attr_name] = converted_value
    
    if requirements:
        result['requirements'] = requirements
    
    # Handle jobs array - collect job names from form fields
    jobs = []
    job_indices = []
    
    # First, collect all job indices
    for key in form_data.keys():
        if key.startswith('jobs.'):
            try:
                index = int(key.split('.')[1])
                job_indices.append(index)
            except (IndexError, ValueError):
                continue
    
    # Sort indices to maintain order, then collect job names
    for index in sorted(job_indices):
        job_name = form_data.get(f'jobs.{index}', '').strip()
        if job_name:  # Only add non-empty job names
            jobs.append(job_name)
    
    # Convert jobs array to numeric string key format to match existing structure
    if jobs:
        jobs_dict = {}
        for i, job_name in enumerate(jobs):
            jobs_dict[str(i + 1)] = job_name
        result['jobs'] = jobs_dict
    
    # Set item properties
    result['setItem'] = True
    
    return result

def parse_set_bonuses_form_data(form_data):
    """Parse set bonuses form data with special handling for piece count and bonus data."""
    result = {}
    
    # Collect all bonus indices
    bonus_indices = set()
    for key in form_data.keys():
        if key.startswith('bonuses.'):
            parts = key.split('.')
            if len(parts) >= 3:
                bonus_indices.add(parts[1])
    
    # Process each bonus
    for index in bonus_indices:
        piece_count = form_data.get(f"bonuses.{index}.pieces", '')
        bonus_type = form_data.get(f"bonuses.{index}.type", '')
        bonus_data = form_data.get(f"bonuses.{index}.bonusData", '')
        
        if piece_count and bonus_type:
            bonus = {
                'type': bonus_type
            }
            
            # Parse bonus data as JSON and merge it
            if bonus_data:
                try:
                    parsed_bonus_data = json.loads(bonus_data)
                    bonus.update(parsed_bonus_data)
                except json.JSONDecodeError:
                    # If JSON parsing fails, skip this bonus
                    continue
            
            # Use piece count as key (convert to int)
            try:
                piece_count_int = int(piece_count)
                result[piece_count_int] = bonus
            except ValueError:
                continue
    
    return result

def convert_value(value):
    """Convert string value to appropriate type."""
    if value == '':
        return None
    elif value.lower() == 'true':
        return True
    elif value.lower() == 'false':
        return False
    elif value.lower() == 'nil':
        return None
    else:
        # Try to convert to number
        try:
            if '.' in value:
                return float(value)
            else:
                return int(value)
        except ValueError:
            return value

@app.route('/assets/<path:filename>')
def serve_assets(filename):
    """Serve assets files for image previews."""
    return send_from_directory(ASSETS_PATH, filename)

@app.route('/search/<data_type>')
def search_data(data_type):
    """Search data and return filtered table rows for HTMX."""
    if data_type not in DATA_FILES:
        return '', 404
    
    search_query = request.args.get('search', '').strip().lower()
    
    # DEBUG: Log search request
    print(f"DEBUG: Search request for {data_type}, query: '{search_query}'")
    
    config = DATA_FILES[data_type]
    file_path = DATA_PATH / config['file']
    
    if not file_path.exists():
        print(f"DEBUG: File not found: {file_path}")
        return '', 404
    
    try:
        # Load the data
        data = lua_manager.read_lua_file(file_path)
        
        # Ensure data is never None, always a dict
        if data is None:
            data = {}
        
        # Handle nested data structures for different file types
        if data_type == 'monsters' and 'monsters' in data:
            data = data['monsters']
        elif data_type == 'items' and 'items' in data:
            data = data['items']
        elif data_type == 'minion_abilities' and 'definitions' in data:
            data = data['definitions']
        elif data_type == 'monster_abilities' and 'definitions' in data:
            data = data['definitions']
        elif data_type in ['quests', 'smith_recipes']:
            # Handle array-based data structures - convert to dict for easier management
            if isinstance(data, list):
                id_field = 'id' if data_type == 'quests' else 'name'
                data_dict = {}
                for item in data:
                    if id_field in item:
                        data_dict[item[id_field]] = item
                data = data_dict
            elif isinstance(data, dict) and len(data) > 0:
                first_key = next(iter(data.keys()))
                if isinstance(first_key, (int, str)) and str(first_key).isdigit():
                    id_field = 'id' if data_type == 'quests' else 'name'
                    data_dict = {}
                    for item in data.values():
                        if isinstance(item, dict) and id_field in item:
                            data_dict[item[id_field]] = item
                    data = data_dict
        
        # Ensure data is still a dict after nested access
        if data is None:
            data = {}
        
        print(f"DEBUG: Loaded {len(data)} items for {data_type}")
        
        # Filter data based on search query
        if search_query:
            filtered_data = {}
            for item_id, item_data in data.items():
                # Search in ID/name
                if search_query in item_id.lower():
                    filtered_data[item_id] = item_data
                    continue
                
                # Search in display name
                if isinstance(item_data, dict):
                    if 'name' in item_data and item_data['name'] and search_query in item_data['name'].lower():
                        filtered_data[item_id] = item_data
                        continue
                    
                    # Search in description
                    if 'description' in item_data and item_data['description'] and search_query in item_data['description'].lower():
                        filtered_data[item_id] = item_data
                        continue
                    
                    # Search in type
                    if 'type' in item_data and item_data['type'] and search_query in item_data['type'].lower():
                        filtered_data[item_id] = item_data
                        continue
                    
                    # Data type specific searches
                    if data_type == 'items':
                        # Search in slot, subType, jobs
                        if 'slot' in item_data and item_data['slot'] and search_query in item_data['slot'].lower():
                            filtered_data[item_id] = item_data
                            continue
                        if 'subType' in item_data and item_data['subType'] and search_query in item_data['subType'].lower():
                            filtered_data[item_id] = item_data
                            continue
                        if 'jobs' in item_data and isinstance(item_data['jobs'], dict):
                            for job in item_data['jobs'].values():
                                if job and search_query in job.lower():
                                    filtered_data[item_id] = item_data
                                    break
                    
                    elif data_type == 'monsters':
                        # Search in abilities, immunities
                        if 'abilities' in item_data and isinstance(item_data['abilities'], list):
                            for ability in item_data['abilities']:
                                if isinstance(ability, dict) and 'id' in ability:
                                    if search_query in ability['id'].lower():
                                        filtered_data[item_id] = item_data
                                        break
                        if 'immunities' in item_data and isinstance(item_data['immunities'], list):
                            for immunity in item_data['immunities']:
                                if search_query in immunity.lower():
                                    filtered_data[item_id] = item_data
                                    break
                    
                    elif data_type == 'jobs':
                        # Search in category, availableSkills, startingSkills
                        if 'category' in item_data and item_data['category'] and search_query in item_data['category'].lower():
                            filtered_data[item_id] = item_data
                            continue
                        if 'availableSkills' in item_data and isinstance(item_data['availableSkills'], list):
                            for skill in item_data['availableSkills']:
                                if search_query in skill.lower():
                                    filtered_data[item_id] = item_data
                                    break
                    
                    elif data_type == 'skills':
                        # Search in target, mpCost
                        if 'target' in item_data and item_data['target'] and search_query in item_data['target'].lower():
                            filtered_data[item_id] = item_data
                            continue
                    
                    elif data_type == 'quests':
                        # Search in giver, status, objective
                        if 'giver' in item_data and item_data['giver'] and search_query in item_data['giver'].lower():
                            filtered_data[item_id] = item_data
                            continue
                        if 'status' in item_data and item_data['status'] and search_query in item_data['status'].lower():
                            filtered_data[item_id] = item_data
                            continue
                        if 'objective' in item_data and isinstance(item_data['objective'], dict):
                            for key, value in item_data['objective'].items():
                                if isinstance(value, str) and search_query in value.lower():
                                    filtered_data[item_id] = item_data
                                    break
            
            data = filtered_data
        
        # Return grid items
        return render_template('partials/grid_items.html', 
                             data=data, 
                             data_type=data_type, 
                             config=config)
    except Exception as e:
        print(f"DEBUG: Error during search: {e}")
        return '', 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 