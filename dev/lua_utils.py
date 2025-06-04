import re
from lupa import LuaRuntime

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
        if isinstance(data, dict) and ('items' in data or 'monsters' in data or 'definitions' in data): # Added 'definitions' for minion/monster abilities
            # This is a complex structure that should be returned directly
            lua_content = self._python_to_lua_complex(data, table_name) # Pass table_name
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
    
    def _python_to_lua_complex(self, data, table_name_hint): # Added table_name_hint
        """Convert complex Python data structures to Lua format with return statement."""
        lines = []
        
        # Determine primary content key and structure based on hint or content
        # This logic might need to be more robust based on all file types
        main_table_var_name = table_name_hint # Default to hint

        if 'RARITY' in data and 'items' in data : # item_definitions.lua like structure
            main_table_var_name = 'itemDefinitions' # This is often the structure
            lines.append("-- Define item rarities")
            lines.append("local RARITY = {")
            for key, value in data['RARITY'].items():
                lines.append(f'    {key} = "{value}",')
            lines.append("}")
            lines.append("")
            lines.append(f"local {main_table_var_name} = {{") # Use main_table_var_name
            lines.append("    items = {")
            for key, value in data['items'].items():
                lines.append(f'        ["{key}"] = {self._format_value(value, 2)},') # Corrected key format
            lines.append("    }")
            lines.append("}")
            lines.append("")
            lines.append(f"return {main_table_var_name}")

        elif 'monsters' in data: # monster_definitions.lua like structure
            main_table_var_name = 'monsterDefinitions'
            lines.append(f"local {main_table_var_name} = {{}}")
            lines.append(f"{main_table_var_name}.monsters = {{")
            for key, value in data['monsters'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append(f"return {main_table_var_name}")

        elif 'definitions' in data: # for abilities files
            # table_name_hint should be like 'monsterAbilities' or 'minionAbilities'
            lines.append(f"local {table_name_hint} = {{}}")
            lines.append(f"{table_name_hint}.definitions = {{")
            for key, value in data['definitions'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append(f"return {table_name_hint}")
        
        # Fallback or other complex structures can be added here
        # For now, if none of the above match, it might indicate an unhandled complex type
        # or it should have been routed to _python_to_lua simple.
        else:
            # This case should ideally not be hit if routing to _python_to_lua_complex is correct.
            # If it's a simple dict that got here, use the simple formatter.
            print(f"Warning: _python_to_lua_complex called with unrecognized structure for {table_name_hint}. Data: {list(data.keys())}")
            return self._python_to_lua(data, table_name_hint)


        return "\n".join(lines)
    
    def _python_to_lua(self, data, table_name, indent=0):
        """Convert Python data to Lua table format."""
        if isinstance(data, list):
            # Handle arrays (like quests and smith recipes)
            lines = []
            if indent == 0: # Top-level call for an array-based file
                lines.append(f"local {table_name} = {{")
            else: # Nested array
                lines.append("{")
            
            for i, item in enumerate(data):
                indent_str = "    " * (indent + 1)
                # Lua arrays are 1-indexed
                lines.append(f"{indent_str}[{i + 1}] = {self._format_value(item, indent + 1)},")
            
            if indent == 0:
                lines.append("}")
                lines.append(f"\nreturn {table_name}")
            else:
                lines.append("    " * indent + "}")
            
            return "\n".join(lines)
        elif isinstance(data, dict):
            lines = []
            if indent == 0: # Top-level call for a dict-based file
                lines.append(f"local {table_name} = {{")
            else: # Nested dict
                lines.append("{")
            
            for key, value in data.items():
                indent_str = "    " * (indent + 1)
                # Ensure keys are correctly formatted (quoted if not valid Lua identifiers)
                if isinstance(key, str) and key.isidentifier() and not key.startswith('_') : # Lua identifiers
                    key_str = key
                else: # Numeric keys or keys with special chars need to be in ["key"] format
                    key_str = f'["{key}"]'
                
                # Removed the extra nesting for simple dict values, should be handled by _format_value recursion
                lines.append(f"{indent_str}{key_str} = {self._format_value(value, indent + 1)},")
            
            if indent == 0:
                lines.append("}")
                lines.append(f"\nreturn {table_name}")
            else:
                lines.append("    " * indent + "}")
            
            return "\n".join(lines)
        else: # Should not happen for top-level data if it's a table
            return self._format_value(data, indent)
    
    def _format_value(self, value, indent):
        """Format a single value for Lua output."""
        indent_str_inner = "    " * (indent + 1)
        indent_str_outer = "    " * indent

        if isinstance(value, str):
            # Escape backslashes and quotes
            escaped_value = value.replace('\\', '\\\\').replace('"', '\\"')
            return f'"{escaped_value}"'
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
                lines.append(f"{indent_str_inner}[{i + 1}] = {self._format_value(item, indent + 1)},")
            lines.append(f"{indent_str_outer}}}")
            return "\n".join(lines)
        elif isinstance(value, dict):
            if not value:
                return "{}"
            lines = ["{"]
            for k, v in value.items():
                # Ensure keys are correctly formatted
                if isinstance(k, str) and k.isidentifier() and not k.startswith('_'):
                    key_str = k
                else:
                    key_str = f'["{k}"]'
                lines.append(f"{indent_str_inner}{key_str} = {self._format_value(v, indent + 1)},")
            lines.append(f"{indent_str_outer}}}")
            return "\n".join(lines)
        elif value is None:
            return "nil"
        else: # Fallback for other types
            return f'"{str(value)}"' 