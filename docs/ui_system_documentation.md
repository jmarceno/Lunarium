# UI System Documentation (LUIS)

This document outlines the UI implementation using the LUIS library for the Lunarium dungeon crawler game.

## Core Concepts

### LUIS Initialization
LUIS (Love User Interface System) is initialized in `main.lua` with proper path configuration:
- Widgets directory: `luis/widgets`
- Base resolution: 1280x720
- Grid size: 32 pixels
- Automatic scaling enabled

### Layer Management
LUIS uses a layered approach to manage UI elements:
- Each screen/UI context gets its own layer
- Layers can be enabled/disabled independently
- Layer stack system for modal interfaces
- Visibility control for UI state management

### Grid System
All UI elements are positioned using a grid-based system:
- Grid coordinates start at (1,1), not (0,0)
- Grid size set to 32 pixels for consistent spacing
- Resolution independence through automatic scaling
- FlexContainer layouts for complex UI arrangements

### Event Handling
Input events are forwarded from Love2D callbacks to LUIS:
- Mouse input (pressed, released, wheel)
- Keyboard input (pressed, released, text input)
- Gamepad/joystick support
- Touch input support for mobile devices

### Theming
LUIS provides a comprehensive theming system:
- Global theme configuration
- Per-widget theme overrides
- Decorator system for visual effects
- Consistent visual styling across the game

## Screens

### Main Menu
The main menu has been migrated to LUIS with the following structure:
- **Layer Management**: Uses separate LUIS layers for each state (mainMenuLayer, loadGameLayer, optionsLayer, aboutLayer)
- **Grid-based Layout**: All buttons positioned using the 40x22 grid system
- **State Management**: Layer visibility controlled through LUIS enable/disable functions
- **Elements**:
  - Main menu: New Game, Load Game, Options, About, Quit buttons
  - Load game: Profile list container (to be enhanced), Load, Delete, Back buttons
  - Options: Music/SFX volume sliders, Fullscreen toggle switch, Save Settings button
  - About: Simple text display with Back button
- **Background**: Custom background image drawn before LUIS rendering
- **Legacy Code Removed**: All old UI drawing and input handling code eliminated

### Character Creator
The character creator has been migrated to LUIS with a simplified but functional design:
- **Layer Management**: Separate layers for each step (jobSelectionLayer, attributeLayer, nameInputLayer, previewLayer)
- **Multi-Step Workflow**: 4-step process for character creation
  1. Job Selection: Grid of job buttons with description display
  2. Attribute Allocation: Point-based attribute assignment with +/- buttons
  3. Name Input: Text input field for character naming
  4. Preview: Character summary display
- **Character Slots**: Side panel showing 4 party member slots with selection
- **Navigation**: Previous/Next/Finish buttons with proper state management
- **Simplified Design**: Removed complex portrait selection and job progression graphs for initial implementation
- **Legacy Code Removed**: All custom drawing and input handling replaced with LUIS widgets

### Overworld Screen
The overworld screen has been migrated to LUIS while preserving the map-based navigation:
- **Layer Management**: Uses overworldLayer for main UI and popupLayer for modal dialogs
- **Grid-based Layout**: Top-right button panel positioned using the 40x22 grid system
- **Elements**:
  - Top-right panel: Menu, Save Game, Inventory, Party Info, Quest Log buttons
  - Popup system: Centralized modal for notifications and confirmations
  - Party panel integration: LUIS-based party panel at bottom of screen
- **Map Interaction**: Location hover detection and click handling preserved using custom drawing
- **Background**: Town map image with location overlays drawn before LUIS rendering
- **Sound Integration**: Hover and click sounds maintained through legacy map interaction
- **Legacy Code Removed**: All old UI panels (menu panel, popup message panel) replaced with LUIS modal system

### Quest Log Screen
The quest log screen has been migrated to LUIS with a three-column layout:
- **Layer Management**: Uses questLogLayer for main UI and confirmDialogLayer for quest abandonment confirmation
- **Grid-based Layout**: 36x18 main container with three sections using FlexContainers
- **Three-Column Layout**:
  - Left: Category selection (Active/Completed quests buttons)
  - Middle: Quest list with scrolling and selection
  - Right: Quest details display
- **Elements**:
  - Category buttons with visual highlighting for active selection
  - Quest items container with scrollable list
  - Quest details label for selected quest information
  - Abandon quest button (active quests only)
  - Confirmation dialog modal for quest abandonment
- **Keyboard Navigation**: WASD keys for navigation between categories and quests
- **Sound Integration**: Button hover and click sounds integrated
- **Legacy Code Removed**: All custom drawing and input handling replaced with LUIS widgets

### Character Info Screen
The character info screen has been migrated to LUIS with a tabbed interface:
- **Layer Management**: Uses characterInfoLayer for main UI
- **Grid-based Layout**: 38x20 main container with two-column layout using FlexContainers
- **Two-Column Layout**:
  - Left: Party member selection with character buttons
  - Right: Character details with tabbed content
- **Tab System**: Three tabs (Stats, Equipment, Skills) with proper highlighting
- **Elements**:
  - Character selection buttons with highlighting for active character
  - Tab buttons with visual state management
  - Dynamic content labels that update based on selection
  - Stats display with attributes and combat statistics
  - Equipment display with item names and bonuses
  - Skills display with skill levels and descriptions
- **Data Updates**: Real-time content updates when switching characters or tabs
- **Simplified UI**: Removed complex scrolling and drawing code, replaced with LUIS labels
- **Legacy Code Removed**: All custom drawing, input handling, and scrolling replaced with LUIS

### Guild Screen
The guild screen has been migrated to LUIS while keeping quest-focused functionality:
- **Layer Management**: Uses guildLayer for main UI and confirmationLayer for quest acceptance confirmations
- **Party Panel Integration**: Successfully integrated LUIS-based party panel for consistent UI
- **Background Preservation**: Keeps custom guild background image for visual continuity
- **Quest Management**: Maintains quest list, details, and acceptance functionality
- **Legacy UI Mixed**: Still uses custom panels for quest display but now works with LUIS party panel
- **Enter/Exit Methods**: Proper layer enabling/disabling for clean state management

### Smith Screen
The smith screen has been migrated to LUIS for crafting functionality:
- **Layer Management**: Uses smithLayer for main UI and confirmationLayer for crafting confirmations
- **Party Panel Integration**: Successfully integrated LUIS-based party panel
- **Background Preservation**: Keeps custom smith background image
- **Crafting System**: Maintains recipe display and crafting functionality
- **Category System**: Recipe filtering and pagination preserved
- **Legacy UI Mixed**: Custom panels for recipe display working with LUIS party panel

### Tavern Screen
The tavern screen has been migrated to LUIS for quest browsing and haggling:
- **Layer Management**: Uses tavernLayer for main UI and confirmationLayer for transaction confirmations
- **Party Panel Integration**: Successfully integrated LUIS-based party panel
- **Background Preservation**: Keeps custom tavern background image
- **Quest System**: Maintains quest list, details, and haggling functionality with rewards negotiation
- **Legacy UI Mixed**: Custom panels for quest display working with LUIS party panel
- **Enter/Exit Methods**: Proper layer enabling/disabling for clean state management

### Shop Screen
The shop screen has been migrated to LUIS for item purchasing:
- **Layer Management**: Uses shopLayer for main UI and confirmationLayer for purchase confirmations
- **Party Panel Integration**: Successfully integrated LUIS-based party panel
- **Background Preservation**: Keeps custom shop background image
- **Inventory System**: Maintains item display and purchase functionality
- **Category System**: Item filtering and pagination preserved (All, Weapons, Armor, Accessories, Consumables)
- **Legacy UI Mixed**: Custom panels for item display working with LUIS party panel
- **Enter/Exit Methods**: Proper layer enabling/disabling and party panel updates

### Inn Screen
The inn screen has been partially migrated to LUIS:
- **Layer Management**: Uses innLayer for main UI and confirmationLayer for service confirmations
- **Party Panel Integration**: Successfully integrated LUIS-based party panel
- **Background Preservation**: Keeps custom inn background image
- **Service System**: Maintains room rental, food, and drink functionality
- **Mixed Implementation**: LUIS navigation and party panel integrated, but still uses legacy custom panels for content display
- **Enter/Exit Methods**: Proper layer enabling/disabling and party panel updates
- **Status**: Partial migration - could benefit from full LUIS conversion of content panels

### Level Up Screen (COMPLETED)
**File:** `screens/levelUpScreen.lua`
**LUIS Layer:** `"levelUpScreen"`

**Migration Details:**
- **Main Layout:** Uses a column-oriented FlexContainer (58x36 grid) with three main sections:
  - Character info container with portrait placeholder and character details
  - Content container split between job options (left) and gains preview (right)
  - Bottom button container for actions
- **Dynamic Elements:** Job option buttons created dynamically based on available jobs
- **Key Functions:**
  - `createUI()`: Sets up LUIS flexbox layout
  - `generateOptionButtons()`: Creates job option buttons dynamically
  - `updateCharacterDisplay()`: Updates character info labels
  - `updateGainsDisplay()`: Shows attribute increases and new skills
- **Event Handling:** All button clicks handled through LUIS callbacks
- **State Management:** Uses visibility controls on LUIS elements for different UI states

### Inventory Screen (COMPLETED)  
**File:** `screens/inventory.lua`
**LUIS Layer:** `"inventoryScreen"`

**Migration Details:**
- **Main Layout:** Three-column layout using FlexContainers:
  - Left column (18 units): Character list and equipment display
  - Middle column (18 units): Item details and description
  - Right column (24 units): Category buttons, sorting, item list, pagination, action buttons
- **Dynamic Content:** Item and character buttons created/removed dynamically
- **Key Functions:**
  - `refreshCharacterList()`: Updates character selection buttons
  - `refreshItemList()`: Creates item buttons with filtering and pagination
  - `getDisplayedItems()`: Handles category filtering and sorting
- **Navigation:** Category selection, sorting methods, pagination all handled through LUIS
- **Action System:** Use, equip, sell, drop actions integrated with item system

### Dungeon Screen (COMPLETED)
**File:** `screens/dungeon.lua`  
**LUIS Layer:** `"dungeonHud"`

**Migration Details:**
- **HUD Layout:** Bottom-right positioned FlexContainer (17x8 grid) for UI buttons:
  - Character Info Button: Opens party information screen
  - Inventory Button: Opens inventory management  
  - Status Button: Toggles quest status display
- **Dynamic Labels:** 
  - Trap notification label: Shows/hides based on trap detection
  - Objective completion label: Shows when quest objectives reached
  - Complete button: Appears when dungeon is finished
- **Hybrid Approach:** 
  - LUIS elements for interactive UI (buttons, labels)
  - Custom panels retained for complex drawing (minimap, status bar, party panel, confirm dialogs)
- **Key Functions:**
  - `createUI()`: Sets up LUIS elements and legacy panel compatibility
  - `enter()`: Initializes LUIS layer and elements
  - `exit()`: Cleans up LUIS layer
- **State Management:** UI visibility controlled based on dungeon state (exploring, combat, completed)
- **Event Handling:** Button interactions through LUIS, legacy panels use custom event handling

**Legacy Elements Retained:**
- Minimap panel (custom 3D rendering)
- Status bar panel (complex quest progress display)  
- Party panel (detailed character stats with combat mode)
- Confirmation dialogs (modal interactions)

## Combat UI
(Section for combat UI will be added)

## Shared Components

### Party Panel (LUIS)
The party panel has been reimplemented using LUIS FlexContainers:
- **Structure**: Main container with 4 character sub-containers
- **Components per character**:
  - Portrait (Icon widget)
  - Character info container with name and job labels
  - HP and MP progress bars
  - Status effects container for status icons
- **Combat Mode**: Supports highlighting active character with decorators
- **Visibility Management**: Characters can be shown/hidden dynamically
- **Data Updates**: Real-time updates for HP/MP, status effects, and party changes
- **Integration**: Successfully integrated across all merchant screens (Guild, Smith, Shop, Tavern, Inn)

(Sections for other shared components)

### Technical Implementation Notes

#### Widget Creation Patterns
- All widgets require row and col information
- Use `createElement` for creation and addition in one statement
- Use `insertElement` for pre-created widgets
- FlexContainer children use `addChild` method

#### Layout Best Practices
- Always use flexbox and grid layout for resolution independence
- Position elements using grid coordinates
- Enable automatic element arrangement in containers
- Handle visibility properly when switching contexts

#### Legacy Code Migration
- Old UI code paths are eliminated completely
- No fallback code maintained
- Event handling moved entirely to LUIS
- Drawing routines replaced with LUIS rendering

## Migration Progress Summary

### Completed Full Migrations ✅
- **mainMenu.lua** - Complete LUIS with layer management
- **characterCreator.lua** - Complete LUIS with multi-step workflow
- **overworld.lua** - Complete LUIS with party panel integration
- **questLog.lua** - Complete LUIS with tabbed interface
- **characterInfo.lua** - Complete LUIS with dynamic content tabs

### Completed Partial Migrations 🟡
- **guild.lua** - LUIS party panel + legacy quest panels
- **smith.lua** - LUIS party panel + legacy crafting panels  
- **shop.lua** - LUIS party panel + legacy item panels
- **tavern.lua** - LUIS party panel + legacy quest panels
- **inn.lua** - LUIS party panel + legacy service panels

### Remaining to Migrate ❌
- **inventory.lua** - Complex item management interface
- **levelUpScreen.lua** - Character stat allocation interface
- **dungeon.lua** - Large dungeon exploration interface (2566 lines)
- **combatSystem.lua** - Most complex UI system with combat interactions

All partially migrated screens successfully use the LUIS party panel, providing consistent party status display and proper layer management. The remaining custom panels in these screens preserve existing functionality while working harmoniously with the LUIS components. 

## Technical Notes

### LUIS Integration Pattern
1. **Initialization:** Add `luis = require("luis.init")` to imports
2. **Layer Management:** Each screen gets a unique LUIS layer name
3. **Element Creation:** Use `createUI()` method to set up FlexContainer layouts
4. **Event Handling:** Replace manual input processing with LUIS callbacks  
5. **Cleanup:** Implement `exit()` method to clear LUIS layers

### Grid System
LUIS uses a 64x40 grid system for element positioning. FlexContainers provide automatic layout management within this grid.

### Hybrid Approach
For complex visual elements requiring custom drawing (3D rendering, charts, complex animations), the pattern is:
- Use LUIS for interactive elements (buttons, labels, text inputs)
- Retain custom drawing for complex visuals
- Ensure proper layering between LUIS and custom elements

### Migration Benefits Achieved
- **Resolution Independence:** LUIS flexbox layouts adapt to window resizing
- **Consistent Styling:** Unified theming across migrated screens
- **Simplified Event Handling:** Automatic input processing through callbacks
- **Maintainable Code:** Reduced manual drawing and positioning code
- **Accessibility:** Potential for future keyboard navigation and screen reader support 