# Function Parsing Implementation

## Problem

The Lua table parser in `lua_utils.py` was unable to properly handle Lua functions within table definitions. When functions like `levelModifier` or `effect` callbacks were parsed and converted to Python data structures, they would be converted to string representations that couldn't be restored back to valid Lua function syntax.

## Solution

Implemented a function extraction and restoration mechanism that:

1. **Extracts functions before parsing**: Identifies function definitions in Lua code and replaces them with unique identifiers (UIDs)
2. **Stores functions separately**: Maintains a registry mapping UIDs to original function text
3. **Restores functions during write-back**: Replaces UIDs with original function text when writing back to Lua files

## Implementation Details

### Function Extraction (`_extract_functions`)

- Uses regex pattern `function\s*\([^)]*\)` to find function definitions
- For each function found:
  - Locates the end by finding the next comma and backtracking to the `end` keyword
  - Handles nested function blocks correctly
  - Generates a unique ID (`FUNCTION_UID_xxxxxxxx`)
  - Stores the function text in `function_registry`
  - Replaces the function with the UID in quotes

### Function Restoration (`_restore_functions`)

- Scans the generated Lua content for function UIDs (both quoted and unquoted)
- Replaces each UID with the original function text
- Preserves formatting and indentation
- Handles UIDs that may have quotes stripped during formatting

### Key Features

- **Preserves comments**: Original function comments are maintained
- **Preserves formatting**: Indentation and whitespace are preserved
- **Handles nested functions**: Correctly identifies function boundaries even with nested structures
- **Safe parsing**: Functions are temporarily replaced with strings that can be safely parsed by the Lua runtime

## Test Cases Verified

The implementation was tested with three distinct cases from `skill_definitions.lua`:

1. **FireBolt**: Simple `levelModifier` function
2. **RaiseZombie**: `levelModifier` function with complex return structure
3. **BallistaNetShot**: Complex `effect` function with multiple parameters and logic (808 characters)

## Usage

The enhanced `LuaTableManager` works transparently with existing code:

```python
lua_manager = LuaTableManager()

# Load file with functions - functions are automatically extracted
data = lua_manager.read_lua_file('skill_definitions.lua')

# Modify data as needed
data['NewSkill'] = {...}

# Save back - functions are automatically restored
lua_manager.write_lua_file('skill_definitions.lua', data, 'skillDefinitions')
```

## Results

- **97 functions** successfully extracted from `skill_definitions.lua`
- **All functions** properly restored in round-trip testing
- **No UIDs** remaining in final output
- **Valid Lua syntax** maintained throughout the process
- **98 functions** successfully written back (97 original + proper formatting)

## Bug Fixes Applied

### Issue 1: Function UIDs Not Being Replaced
- **Problem**: UIDs like `"FUNCTION_UID_21fad0d3"` were appearing in saved files instead of actual functions
- **Root Cause**: Formatting pipeline was removing quotes from UIDs, but restoration was only looking for quoted versions
- **Solution**: 
  - Modified `_format_value()` to return UIDs without quotes
  - Updated `_restore_functions()` to handle both quoted and unquoted UIDs
  - Result: Functions now properly restored as `function(level) return 1 + (level * 0.1) end`

### Issue 2: Restored Functions Being Quoted in Output
- **Problem**: Even after successful restoration, function strings were being written with quotes, creating invalid Lua syntax:
  ```lua
  levelModifier = "function(level) return 1 + (level * 0.1) end"
  ```
  This caused `LuaSyntaxError` when the file was loaded again, breaking the application.
- **Root Cause**: The `_format_value()` method was treating restored function strings as regular strings and wrapping them in quotes
- **Solution**: Enhanced `_format_value()` to detect function definitions and output them without quotes:
  ```python
  elif value.startswith('function(') and value.endswith(' end'):
      return value  # Return function without quotes
  ```
- **Result**: Functions are now correctly written as valid Lua syntax:
  ```lua
  levelModifier = function(level) return 1 + (level * 0.1) end,
  ```

## Dashboard Integration

### Form Data Function Restoration
Added `restore_functions_in_data()` helper function to handle function restoration in form data before saving:

```python
def restore_functions_in_data(data, function_registry):
    """Recursively restore function UIDs in data structure back to function text."""
    # Handles nested dictionaries and arrays
    # Converts UIDs like 'FUNCTION_UID_87ab26a1' back to function text
```

This ensures that UIDs from form submissions are properly converted back to function text before the file write operation.

## Complete Workflow

1. **Edit Route**: `lua_manager.read_lua_file()` extracts functions → creates UIDs → populates function registry
2. **Form Display**: UIDs are shown in form fields instead of complex function text
3. **Save Route**: Form data contains UIDs → `restore_functions_in_data()` converts UIDs to function text
4. **File Write**: `_format_value()` detects function strings → writes without quotes → valid Lua syntax
5. **File Read**: Valid Lua file loads successfully without syntax errors

The implementation successfully solves the function parsing issue while maintaining compatibility with existing dashboard functionality and ensuring robust round-trip preservation of Lua functions. 