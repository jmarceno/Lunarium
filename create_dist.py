import os
import shutil
import zipfile
import re

# --- Configuration ---
LOVE_INSTALL_DIR = r"C:\Program Files\LOVE"
# Assumes the script is in the game's root directory
GAME_ROOT_DIR = os.getcwd()
DIST_DIR_NAME = "dist"
CONF_LUA_FILENAME = "conf.lua" # Standard name for LÖVE config

# Relative paths from GAME_ROOT_DIR.
# assets/sources/** is handled by excluding the 'assets/sources' folder.
EXCLUDED_FOLDERS_REL = [
    ".cursor",
    ".vscode",
    ".git",
    DIST_DIR_NAME, # Exclude the distribution directory itself
    "docs",
    "planning",
    "dev",
    os.path.join("assets", "sources"),
    os.path.join("assets", "ExampleCode"),
    os.path.join("assets", "harc-master.zip"),
]

# Files to exclude, relative to GAME_ROOT_DIR
EXCLUDED_FILES_REL = [
    ".gitignore",
    "rundatamanager.bat",
    "rungame.bat",
    "create_dist.py" # Exclude this script itself
]

# Files to copy from LOVE_INSTALL_DIR to the dist folder (excluding love.exe, which is handled separately)
# This list is based on common Love2D 11.x distributions. Adjust if your version differs.
FILES_TO_COPY_FROM_LOVE_DIR = [
    'love.dll',
    'SDL2.dll',
    'OpenAL32.dll',
    'lua51.dll', # Or lua.dll, luajit.dll depending on Love2D build
    'mpg123.dll',
    'msvcr120.dll',
    'msvcp120.dll',
    # Add other DLLs like 'libcrypto-1_1-x64.dll', 'libssl-1_1-x64.dll', 'zlib1.dll' if needed by your Love2D version
]

def remove_lua_comments(lua_code):
    """
    Removes block and single-line comments from a string of Lua code.
    WARNING: This simple regex-based approach may break strings containing '--'.
    """
    # Remove block comments (e.g., --[[ ... ]], --[=[ ... ]=])
    # Non-greedy match for content within block comments.
    lua_code = re.sub(r"--\[(=*)\[.*?ुट\1\]", "", lua_code, flags=re.DOTALL)
    
    # Remove single-line comments (e.g., -- comment)
    lines = lua_code.splitlines()
    cleaned_lines = [re.sub(r"--.*$", "", line) for line in lines]
    
    return "\n".join(cleaned_lines)

def create_distributable():
    """
    Creates the distributable package for the Love2D game.
    """
    print("Starting distribution packaging process...")

    game_name = "Lunarium"
    
    love_file_name = f"{game_name}.love"
    final_exe_name = f"{game_name}.exe"
    
    dist_path = os.path.join(GAME_ROOT_DIR, DIST_DIR_NAME)
    love_file_full_path = os.path.join(dist_path, love_file_name)
    final_exe_full_path = os.path.join(dist_path, final_exe_name)
    conf_lua_path = os.path.join(GAME_ROOT_DIR, CONF_LUA_FILENAME)

    # Normalize exclusion paths for consistent comparisons
    norm_excluded_folders = [os.path.normpath(p) for p in EXCLUDED_FOLDERS_REL]
    norm_excluded_files = [os.path.normpath(p) for p in EXCLUDED_FILES_REL]

    original_conf_content = None
    conf_actually_modified = False

    try:
        # 0. Temporarily modify conf.lua
        print(f"Attempting to modify {CONF_LUA_FILENAME} for distribution...")
        if os.path.exists(conf_lua_path):
            try:
                with open(conf_lua_path, 'r', encoding='utf-8') as f:
                    original_conf_content = f.read()
                
                new_content = re.sub(r"(t\.console\s*=\s*)true(\s*(?:--.*)?)$", 
                                     r"\1false\2", 
                                     original_conf_content, 
                                     flags=re.MULTILINE)
                
                if new_content != original_conf_content:
                    with open(conf_lua_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    conf_actually_modified = True
                    print(f"  Temporarily changed t.console to false in {conf_lua_path}")
                else:
                    print(f"  t.console was not 'true' or not found as expected in {conf_lua_path}. No changes made to it.")
            except Exception as e:
                print(f"  Error modifying {conf_lua_path}: {e}. Proceeding without modification.")
        else:
            print(f"  Warning: {conf_lua_path} not found. Skipping t.console modification.")

        # 1. Clean and create dist directory
        print(f"Preparing distribution directory: {dist_path}")
        if os.path.exists(dist_path):
            print(f"  Removing existing dist directory: {dist_path}")
            shutil.rmtree(dist_path)
        os.makedirs(dist_path)
        print(f"  Created dist directory: {dist_path}")

        # 2. Create .love file
        print(f"Creating LÖVE archive: {love_file_full_path}...")
        try:
            with zipfile.ZipFile(love_file_full_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for root, dirs, files in os.walk(GAME_ROOT_DIR, topdown=True):
                    current_root_rel_path = os.path.normpath(os.path.relpath(root, GAME_ROOT_DIR))

                    dirs_to_remove = []
                    for d_name in dirs:
                        dir_rel_path = os.path.normpath(os.path.join(current_root_rel_path, d_name))
                        if dir_rel_path == ".":
                            dir_rel_path = os.path.normpath(d_name)

                        is_excluded = False
                        if dir_rel_path in norm_excluded_folders:
                            is_excluded = True
                        else:
                            for ex_fold in norm_excluded_folders:
                                if dir_rel_path.startswith(ex_fold + os.path.sep):
                                    is_excluded = True
                                    break
                        if is_excluded:
                            dirs_to_remove.append(d_name)
                    
                    if dirs_to_remove:
                        print(f"  Excluding directories: {', '.join(dirs_to_remove)} from {current_root_rel_path if current_root_rel_path != '.' else 'root'}")
                    for d_to_remove in dirs_to_remove:
                        dirs.remove(d_to_remove)

                    for file_name in files:
                        file_abs_path = os.path.join(root, file_name)
                        file_rel_path = os.path.normpath(os.path.relpath(file_abs_path, GAME_ROOT_DIR))

                        # General exclusion for .md and .zip files
                        if file_name.endswith(".md") or file_name.endswith(".zip"):
                            print(f"  Excluding markdown file: {file_rel_path}")
                            continue

                        # Check against explicit exclusion list for other files
                        if file_rel_path in norm_excluded_files:
                            print(f"  Excluding file (explicitly listed): {file_rel_path}")
                            continue
                        
                        if file_name.endswith(".lua") and file_rel_path != CONF_LUA_FILENAME:
                            try:
                                print(f"  Adding (and stripping comments from) Lua file: {file_rel_path}")
                                with open(file_abs_path, 'r', encoding='utf-8') as f_lua:
                                    lua_content = f_lua.read()
                                processed_lua_content = remove_lua_comments(lua_content)
                                zipf.writestr(file_rel_path, processed_lua_content.encode('utf-8'))
                            except Exception as e:
                                print(f"    Warning: Could not process/add Lua file {file_rel_path}: {e}. Adding original.")
                                zipf.write(file_abs_path, arcname=file_rel_path)
                        elif file_rel_path == CONF_LUA_FILENAME and os.path.exists(conf_lua_path):
                            print(f"  Adding modified {CONF_LUA_FILENAME}: {file_rel_path}")
                            zipf.write(conf_lua_path, arcname=file_rel_path) # Use current disk version
                        else:
                            print(f"  Adding to archive: {file_rel_path}")
                            zipf.write(file_abs_path, arcname=file_rel_path)
            print(".love file created successfully.")
        except Exception as e:
            print(f"Error creating .love file: {e}")
            raise 

        # 3. Prepare game executable by copying love.exe
        print(f"Preparing base executable: {final_exe_full_path}")
        love_exe_original_path = os.path.join(LOVE_INSTALL_DIR, 'love.exe')
        if not os.path.exists(love_exe_original_path):
            print(f"Error: love.exe not found at {love_exe_original_path}.")
            print(f"Please check the LOVE_INSTALL_DIR variable (currently: '{LOVE_INSTALL_DIR}') in the script.")
            return 
        
        try:
            shutil.copy2(love_exe_original_path, final_exe_full_path)
        except Exception as e:
            print(f"Error copying love.exe: {e}")
            return 

        # 4. Combine love.exe and .love file (binary append)
        print(f"Fusing {love_file_name} into {final_exe_name}...")
        try:
            with open(final_exe_full_path, 'ab') as exe_file, open(love_file_full_path, 'rb') as love_archive:
                exe_file.write(love_archive.read())
            print("Fusion successful.")
        except Exception as e:
            print(f"Error fusing .love file into executable: {e}")
            return 

        # 5. Copy required DLLs and other files from Love2D installation
        print(f"Copying required files from {LOVE_INSTALL_DIR} to {dist_path}...")
        copied_dll_count = 0
        for file_to_copy in FILES_TO_COPY_FROM_LOVE_DIR:
            source_file_path = os.path.join(LOVE_INSTALL_DIR, file_to_copy)
            if os.path.exists(source_file_path):
                try:
                    shutil.copy2(source_file_path, dist_path)
                    copied_dll_count += 1
                except Exception as e:
                    print(f"    Warning: Could not copy {file_to_copy}: {e}")
            else:
                print(f"    Warning: {file_to_copy} not found in {LOVE_INSTALL_DIR}. Skipping.")
        print(f"{copied_dll_count} DLLs/files copied.")

        # 6. Clean up temporary .love file as it's now part of the .exe
        print(f"Cleaning up temporary file: {love_file_full_path}")
        try:
            os.remove(love_file_full_path)
        except OSError as e:
            print(f"Warning: Could not remove temporary .love file '{love_file_full_path}': {e}")

        print("-" * 40)
        print(f"Distribution created successfully in: {os.path.abspath(dist_path)}")
        print(f"Main executable: {os.path.abspath(final_exe_full_path)}")
        print("To run your game, execute this file from the 'dist' directory,")
        print("or copy the entire 'dist' directory to another machine.")
        print("Remember to test the distribution, preferably on a machine")
        print("that does not have LÖVE installed to ensure all dependencies are met.")
        print("-" * 40)

    finally:
        if conf_actually_modified and original_conf_content is not None:
            try:
                with open(conf_lua_path, 'w', encoding='utf-8') as f:
                    f.write(original_conf_content)
                print(f"Restored original content of {conf_lua_path}")
            except Exception as e:
                print(f"Critical Error: Failed to restore original content of {conf_lua_path}: {e}")
                print("Please manually check and restore it if necessary!")

if __name__ == '__main__':
    if not os.path.isdir(LOVE_INSTALL_DIR):
        print(f"Error: LÖVE installation directory not found at '{LOVE_INSTALL_DIR}'.")
        print("Please set the LOVE_INSTALL_DIR variable at the top of this script correctly.")
    else:
        create_distributable() 