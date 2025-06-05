import re
from lupa import LuaRuntime

class LuaTableManager:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
    
    def read_lua_file(self, file_path):
        """Read and parse a Lua file, returning Python data structures."""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Execute the Lua code and get the returned table
            result = self.lua.execute(content)
            
            # Convert to Python data structures
            if result:
                converted = self._lua_to_python(result)
                return converted
            else:
                # Fallback: try to extract from globals if no return value
                result = {}
                for key, value in self.lua.globals().items():
                    if not key.startswith('_') and hasattr(value, 'items'):
                        try:
                            result[key] = self._lua_to_python(value)
                        except Exception as e:
                            continue
                return result
                
        except Exception as e:
            import traceback
            traceback.print_exc()
            return {}
    
    def _extract_table_name(self, content):
        """Extract the main table name from Lua file content."""
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
                # First, collect all items
                items = list(lua_obj.items())
                
                # Check if this looks like a Lua array (consecutive integer keys starting from 1)
                if items and self._is_lua_array(items):
                    # Convert to Python list, preserving order
                    max_index = max(int(k) for k, v in items)
                    array_result = [None] * max_index
                    for key, value in items:
                        converted_value = self._lua_to_python(value)
                        array_result[int(key) - 1] = converted_value  # Lua is 1-indexed
                    return array_result
                else:
                    # Regular dictionary
                    for key, value in items:
                        converted_value = self._lua_to_python(value)
                        result[key] = converted_value
                    return result
            except Exception as e:
                return {}
        else:
            # Try to handle as array/list
            try:
                iter(lua_obj)
                return [self._lua_to_python(item) for item in lua_obj]
            except (TypeError, AttributeError):
                # If it's not iterable, convert to string representation
                try:
                    return str(lua_obj)
                except Exception:
                    return None
    
    def _is_lua_array(self, items):
        """Check if a list of (key, value) pairs represents a Lua array."""
        if not items:
            return False
        
        # All keys must be integers
        try:
            keys = [int(k) for k, v in items]
        except (ValueError, TypeError):
            return False
        
        # Keys should be consecutive integers starting from 1
        keys.sort()
        expected_keys = list(range(1, len(keys) + 1))
        return keys == expected_keys
    
    def write_lua_file(self, file_path, data, table_name):
        """Write Python data back to a Lua file."""
        # Check if this is a complex table structure (like item_definitions.lua)
        if isinstance(data, dict) and ('items' in data or 'monsters' in data or 'definitions' in data):
            # This is a complex structure that should be returned directly
            lua_content = self._python_to_lua_complex(data, table_name)
        else:
            # Simple table structure
            lua_content = self._python_to_lua(data, table_name, 0)
        
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(lua_content)
        except Exception as e:
            raise
    
    def _python_to_lua_complex(self, data, table_name_hint):
        """Convert complex Python data structures to Lua format with return statement."""
        lines = []
        
        main_table_var_name = table_name_hint

        if 'RARITY' in data and 'items' in data:  # item_definitions.lua like structure
            main_table_var_name = 'itemDefinitions'
            lines.append("-- Define item rarities")
            lines.append("local RARITY = {")
            for key, value in data['RARITY'].items():
                lines.append(f'    {key} = "{value}",')
            lines.append("}")
            lines.append("")
            lines.append(f"local {main_table_var_name} = {{")
            lines.append("    items = {")
            for key, value in data['items'].items():
                lines.append(f'        ["{key}"] = {self._format_value(value, 2)},')
            lines.append("    }")
            lines.append("}")
            lines.append("")
            lines.append(f"return {main_table_var_name}")

        elif 'monsters' in data:  # monster_definitions.lua like structure
            main_table_var_name = 'monsterDefinitions'
            lines.append(f"local {main_table_var_name} = {{}}")
            lines.append(f"{main_table_var_name}.monsters = {{")
            for key, value in data['monsters'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append(f"return {main_table_var_name}")

        elif 'definitions' in data:  # for abilities files
            lines.append(f"local {table_name_hint} = {{}}")
            lines.append(f"{table_name_hint}.definitions = {{")
            for key, value in data['definitions'].items():
                lines.append(f'    ["{key}"] = {self._format_value(value, 1)},')
            lines.append("}")
            lines.append("")
            lines.append(f"return {table_name_hint}")
        else:
            # Fallback to simple formatter
            return self._python_to_lua(data, table_name_hint, 0)

        return "\n".join(lines)
    
    def _python_to_lua(self, data, table_name, indent=0):
        """Convert Python data to Lua table format."""
        if isinstance(data, list):
            # Handle arrays (like quests and smith recipes)
            lines = []
            if indent == 0:  # Top-level call for an array-based file
                lines.append(f"local {table_name} = {{")
            else:  # Nested array
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
            if indent == 0:  # Top-level call for a dict-based file
                lines.append(f"local {table_name} = {{")
            else:  # Nested dict
                lines.append("{")
            
            for key, value in data.items():
                indent_str = "    " * (indent + 1)
                # Ensure keys are correctly formatted
                if isinstance(key, str) and key.isidentifier() and not key.startswith('_'):
                    key_str = key
                else:
                    key_str = f'["{key}"]'
                
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
        indent_str_inner = "    " * (indent + 1)
        indent_str_outer = "    " * indent

        if value is None:
            return "nil"
        elif isinstance(value, str):
            # Escape backslashes and quotes for regular strings
            escaped_value = value.replace('\\', '\\\\').replace('"', '\\"')
            return f'"{escaped_value}"'
        elif isinstance(value, bool):
            return "true" if value else "false"
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, list):
            if not value:
                return "{}"
            
            # Use simple array format for lists - this is the key fix for the array corruption
            lines = ["{"]
            for item in value:
                lines.append(f"{indent_str_inner}{self._format_value(item, indent + 1)},")
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
        else:
            return f'"{str(value)}"' 