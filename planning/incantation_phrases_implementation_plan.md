# Incantation Phrases Implementation Plan

## Original Prompt (from todos_bugs.md lines 3-6)
```
- Add incantation phrases to spells and show them somewhere on screen while the spell is ticking
  - This would require a new field at skills to hold a list of phrases that will be said
  - A system to be sure to show all the phrases and to only show the last one on cast - How to control the timming as each spell has a different cast time and will have a different number of phrases (add more phrases to spells that have a longer cast?)
  - Add speach bubbles over the char portrait at screens/ui_slices/partyPanel.lua, and show the phrases there
```

## Changelog
- **2024-12-19**: Initial plan creation based on incantation phrases feature request

## Current System Analysis

Based on my review of the codebase, the current spell casting system includes:

1. **Spell Queue System**: Already implemented in `gameplay/combatSystem.lua` and `gameplay/combat/coreFunctions.lua`
   - Spells have casting times and progress over time
   - Visual progress bars are shown in the UI
   - Spells are queued and executed when casting completes

2. **Skill Definitions**: Located in `data/skill_definitions.lua`
   - Skills have properties like `castingTime`, `name`, `description`, etc.
   - Currently support various effects and modifiers

3. **Party Panel UI**: Located in `screens/ui_slices/partyPanel.lua`
   - Shows character portraits, HP/MP bars, status effects
   - Has separate combat and non-combat drawing modes
   - Character portraits are positioned at specific coordinates

## Implementation Plan

### Phase 1: Data Structure Modifications

#### 1.1. Add Incantation Phrases to Skill Definitions
**File**: `data/skill_definitions.lua`
**Action**: Add new field `incantationPhrases` to all skill definitions that have a castingTime bigger than 1

```lua
-- Example modification for each skill:
FireBolt = {
    name = "Fire Bolt",
    description = "A basic fire attack spell.",
    type = "magical",
    element = "fire",
    target = "single_enemy",
    mpCost = 6,
    basePower = 120,
    formula = "magical",
    damageType = "fire",
    castingTime = 2,
    maxLevel = 5,
    incantationPhrases = {
        "I call upon the flames...",
        "Let fire consume my enemies!"
    },
    -- ... rest of skill definition
}
```


#### 1.2. Add Incantation State to Spell Queue
**File**: `gameplay/combat/coreFunctions.lua`
**Action**: Modify the spell queue entry structure in `addToSpellQueue` function

```lua
-- In addToSpellQueue function, add incantation tracking:
local entry = {
    caster = caster,
    skill = skill,
    target = target,
    progress = 0,
    totalCastingTime = skill.castingTime,
    castingTimeRemaining = skill.castingTime,
    isCasting = true,
    -- NEW FIELDS FOR INCANTATIONS:
    incantationPhrases = skill.incantationPhrases or {},
    currentPhraseIndex = 0, -- Start at 0, will increment to 1 for first phrase
    phrasesShown = {}, -- Array to track which phrases have been displayed
    accumulatedText = "", -- The full text displayed in the bubble (additive)
    phraseDisplayTime = 0, -- How long current phrase has been displayed
    lastPhraseShown = false,
    postCastDisplayTimer = 0, -- Timer for keeping bubble visible after cast
    isPostCast = false -- Flag to indicate spell is complete but bubble still showing
}
```

### Phase 2: Incantation Timing System

#### 2.1. Create Incantation Timing Logic
**File**: `gameplay/combat/coreFunctions.lua`
**Action**: Add new function `updateIncantationPhrases` and integrate it into `updateSpellQueueTime`

**Logic**:
- Calculate phrase intervals based on casting time and number of phrases
- Add phrases to accumulated text at regular intervals during casting
- Ensure all phrases are visible in the bubble when spell completes
- Keep bubble visible for 2 seconds after spell is cast
- Handle spells with different numbers of phrases appropriately

**Implementation Details**:
```lua
-- New function to handle incantation phrase progression
local function updateIncantationPhrases(spell, dt)
    if not spell.incantationPhrases or #spell.incantationPhrases == 0 then
        return
    end
    
    local totalPhrases = #spell.incantationPhrases
    
    -- Handle post-cast display timer
    if spell.isPostCast then
        spell.postCastDisplayTimer = spell.postCastDisplayTimer + dt
        return -- Don't update phrases during post-cast display
    end
    
    if totalPhrases == 1 then
        -- Single phrase: show at the beginning
        if spell.currentPhraseIndex == 0 then
            spell.currentPhraseIndex = 1
            spell.accumulatedText = spell.incantationPhrases[1]
            table.insert(spell.phrasesShown, 1)
        end
        return
    end
    
    -- Multiple phrases: distribute evenly across casting time
    local phraseInterval = spell.totalCastingTime / totalPhrases
    local elapsedTime = spell.totalCastingTime - spell.castingTimeRemaining
    local expectedPhraseIndex = math.floor(elapsedTime / phraseInterval) + 1
    
    -- Ensure we don't exceed available phrases
    expectedPhraseIndex = math.min(expectedPhraseIndex, totalPhrases)
    
    -- Add new phrases to accumulated text if they should be shown
    if expectedPhraseIndex > spell.currentPhraseIndex then
        for i = spell.currentPhraseIndex + 1, expectedPhraseIndex do
            if not spell.phrasesShown[i] then
                -- Add phrase to accumulated text
                if spell.accumulatedText ~= "" then
                    spell.accumulatedText = spell.accumulatedText .. "\n" .. spell.incantationPhrases[i]
                else
                    spell.accumulatedText = spell.incantationPhrases[i]
                end
                table.insert(spell.phrasesShown, i)
            end
        end
        spell.currentPhraseIndex = expectedPhraseIndex
        spell.phraseDisplayTime = 0 -- Reset display timer for new phrase
    end
    
    -- Handle last phrase special case and ensure all phrases are shown
    if spell.castingTimeRemaining <= 0 and not spell.lastPhraseShown then
        -- Make sure all phrases are in the accumulated text
        for i = 1, totalPhrases do
            if not spell.phrasesShown[i] then
                if spell.accumulatedText ~= "" then
                    spell.accumulatedText = spell.accumulatedText .. "\n" .. spell.incantationPhrases[i]
                else
                    spell.accumulatedText = spell.incantationPhrases[i]
                end
                table.insert(spell.phrasesShown, i)
            end
        end
        spell.lastPhraseShown = true
        spell.isPostCast = true
        spell.postCastDisplayTimer = 0
        spell.phraseDisplayTime = 0
    end
    
    spell.phraseDisplayTime = spell.phraseDisplayTime + dt
end
```

#### 2.2. Integrate Incantation Updates into Spell Queue Processing
**File**: `gameplay/combat/coreFunctions.lua`
**Action**: Modify `updateSpellQueueTime` function to call incantation update and handle post-cast cleanup

```lua
-- In updateSpellQueueTime function, add after the existing spell progress logic:
-- Update incantation phrases
updateIncantationPhrases(spell, dt)

-- Handle post-cast cleanup (remove spells after 2 seconds of post-cast display)
if spell.isPostCast and spell.postCastDisplayTimer >= 2.0 then
    -- Remove the spell from queue after post-cast display period
    table.remove(self.spellQueue, i)
    i = i - 1 -- Adjust index since we removed an element
end
```

### Phase 3: Speech Bubble UI System

#### 3.1. Create Speech Bubble Drawing Module
**File**: `screens/ui_slices/speechBubble.lua` (NEW FILE)
**Action**: Create a reusable speech bubble component

**Requirements**:
- Draw speech bubbles above character portraits
- Handle text wrapping for multi-line accumulated text
- Support line breaks for phrase separation
- Fade in/out animations
- Positioning relative to character portraits in party panel
- Auto-resize bubble based on accumulated text length

```lua
-- Speech bubble drawing utility
local speechBubble = {
    -- Draw a speech bubble at the specified position with multi-line text
    draw = function(text, x, y, maxWidth, characterIndex)
        -- Implementation for drawing speech bubble with accumulated text
        -- Include tail pointing to character portrait
        -- Handle multi-line text with proper line breaks
        -- Auto-size bubble based on text content
        -- Support proper vertical spacing between lines
    end,
    
    -- Calculate bubble dimensions for given multi-line text
    calculateSize = function(text, maxWidth)
        -- Split text by line breaks (\n)
        -- Calculate width and height for all lines
        -- Return total width, height for the bubble
    end,
    
    -- Helper function to split text into lines
    splitLines = function(text)
        -- Split text by \n characters
        -- Return array of individual lines
    end
}
```

#### 3.2. Integrate Speech Bubbles into Party Panel
**File**: `screens/ui_slices/partyPanel.lua`
**Action**: Modify `drawCombat` function to show incantation phrases

**Integration Points**:
- Add speech bubble drawing after character rendering
- Position bubbles above character portraits
- Access spell queue from combat system to get current phrases
- Only show bubbles for characters actively casting with phrases

**Specific Code Location**: After line ~195 in the character drawing loop

```lua
-- NEW: Draw incantation speech bubbles (add in drawCombat function)
-- After drawing character status effects, add:
if self.combatSystem and self.combatSystem.spellQueue then
    for _, spell in ipairs(self.combatSystem.spellQueue) do
        if spell.caster == character and spell.incantationPhrases 
           and #spell.incantationPhrases > 0 and spell.accumulatedText ~= "" then
            -- Draw speech bubble above character portrait with accumulated text
            speechBubble:draw(spell.accumulatedText, x + portraitSpace/2, self.y - 20, 200, i)
        end
    end
end
```

#### 3.3. Pass Combat System Reference to Party Panel
**File**: `gameplay/combatSystem.lua`
**Action**: Modify combat system to pass reference to party panel

**Location**: In the `draw` function where party panel is called

```lua
-- Modify existing party panel call to include combat system reference
partyPanel:setCombatMode(true, self.party)
partyPanel.combatSystem = self -- NEW: Pass reference for spell queue access
partyPanel:draw()
```

### Phase 4: Incantation Content Creation

#### 4.1. Add Incantation Phrases to All Relevant Skills
**File**: `data/skill_definitions.lua`
**Action**: Add `incantationPhrases` field to all spells with casting time > 1

**Guidelines for Content Creation**:
- Magical spells: mystical incantations
- Physical abilities: battle cries or technique names
- Healing spells: prayers or healing words
- Utility spells: focused commands

**Example Additions**:
```lua
FireBolt = {
    -- existing properties...
    incantationPhrases = {
        "I call upon the flames of destruction...",
        "Let fire consume my enemies!"
    }
    -- Result: Both phrases will accumulate in bubble:
    -- "I call upon the flames of destruction...
    --  Let fire consume my enemies!"
},

Heal = {
    -- existing properties...
    incantationPhrases = {
        "By the light that binds us...",
        "Let healing energy flow through me...",
        "Restore what was broken!"
    }
    -- Result: All three phrases will accumulate in bubble:
    -- "By the light that binds us...
    --  Let healing energy flow through me...
    --  Restore what was broken!"
},

ShieldBash = {
    -- existing properties...
    incantationPhrases = {
        "For honor and glory!",
        "Take this!"
    }
    -- Result: Both phrases will accumulate in bubble:
    -- "For honor and glory!
    --  Take this!"
}
```

### Phase 5: Testing and Refinement

#### 5.1. Visual Timing Adjustments
**Action**: Fine-tune phrase display timing and animations
**Considerations**:
- Ensure accumulated phrases are readable during casting and 2-second post-cast period
- Adjust bubble positioning to avoid UI overlap, especially with longer accumulated text
- Test with spells of various casting times and different numbers of phrases
- Verify bubble auto-sizing works correctly with multi-line content
- Test readability with maximum expected phrase accumulation

#### 5.2. Performance Optimization
**Action**: Ensure speech bubble rendering doesn't impact performance
**Areas to check**:
- Text measurement and wrapping efficiency for multi-line content
- Bubble drawing optimization with variable text sizes
- Memory usage for accumulated phrase storage
- Efficient line-splitting and text rendering
- Post-cast timer management to prevent memory leaks

### Phase 6: Documentation Creation

#### 6.1. Create Feature Documentation
**File**: `docs/incantation_phrases_system.md` (NEW FILE)
**Action**: Document the complete incantation phrases system

**Documentation Contents**:
- Feature overview and purpose
- Technical implementation details
- How to add incantations to new skills
- Additive phrase accumulation system explanation
- Timing calculation system explanation
- Post-cast display behavior (2-second retention)
- UI positioning and rendering details
- Multi-line text handling and bubble auto-sizing
- Content creation guidelines
- Known limitations and future improvements

## Technical Dependencies and Considerations

### Dependencies
1. **Existing Spell Queue System**: Feature builds on the already-implemented casting time system
2. **Party Panel UI**: Requires integration with existing character display system
3. **Asset Manager**: May need font and bubble graphics resources

### Potential Issues and Clarifications Needed

1. **Phrase Timing Distribution**:
   - **Issue**: How to handle spells with vastly different casting times and phrase counts
   - **Current Approach**: Distribute phrases evenly across casting time
   - **Alternative**: Fixed minimum time between phrases regardless of total casting time
   - **Clarification Needed**: Which approach is preferred?

2. **UI Overlap Prevention**:
   - **Issue**: Multiple characters casting simultaneously could create overlapping speech bubbles, especially with accumulating multi-line text
   - **Solution Required**: Stagger bubble positions or queue phrase display, account for variable bubble sizes

3. **Phrase Content Scaling**:
   - **Issue**: Should longer-casting spells automatically get more phrases?
   - **Current Plan**: Manually assign appropriate number of phrases per spell

4. **Non-Combat Usage**:
   - **Issue**: Should incantations appear outside of combat (e.g., town healing)?
   - **Current Scope**: Only implemented for combat scenarios   

5. **Localization Support**:
   - **Issue**: How to handle translation of incantation phrases
   - **Current Implementation**: Hardcoded English phrases
   - **Future Requirement**: Localization system integration

6. **Audio Integration**:
   - **Issue**: Should incantations be accompanied by voice acting or sound effects?
   - **Current Scope**: Visual-only implementation
   - **Future Enhancement**: Audio phrase playback

## Implementation Order and Dependencies

1. **Phase 1** (Data Structure) → **Phase 2** (Timing Logic) → **Phase 3** (UI Integration)
2. **Phase 4** (Content) can be done in parallel with Phase 3
3. **Phase 5** (Testing) requires all previous phases
4. **Phase 6** (Documentation) should be completed after implementation

## Success Criteria

- ✅ All spells with casting time > 1 have appropriate incantation phrases
- ✅ Phrases accumulate correctly during spell casting with proper timing
- ✅ All phrases are visible in bubble when spell completes
- ✅ Speech bubbles remain visible for 2 seconds after spell completion
- ✅ Speech bubbles position correctly above character portraits and auto-resize
- ✅ Multi-line text displays properly with line breaks
- ✅ No UI overlap or performance issues
- ✅ System works for all character positions in party panel
- ✅ Post-cast cleanup removes spell entries after display period
- ✅ Complete documentation created at `docs/incantation_phrases_system.md`

## Post-Implementation Tasks

1. **Create documentation file**: `docs/incantation_phrases_system.md`
2. **Update Content Manager**: When managing skills, add a field to allow the user to add the incantation phrases `dev\app.py` and `dev\manage.html`
3. **Content review**: Ensure all phrases are thematically appropriate and spell-specific
4. **Accessibility considerations**: Ensure phrases are readable and don't interfere with combat readability

## Files to be Modified/Created

### Modified Files:
- `data/skill_definitions.lua` - Add incantation phrases to skills
- `gameplay/combat/coreFunctions.lua` - Add incantation timing system
- `gameplay/combatSystem.lua` - Pass combat system reference to party panel
- `screens/ui_slices/partyPanel.lua` - Integrate speech bubble display
- `dev\app.py` and `dev\manage.html` - Content Manager

### New Files:
- `screens/ui_slices/speechBubble.lua` - Speech bubble drawing utility
- `docs/incantation_phrases_system.md` - Feature documentation

## Estimated Implementation Time
- **Phase 1-3**: Core system implementation (4-6 hours)
- **Phase 4**: Content creation for all skills (2-3 hours)
- **Phase 5**: Testing and refinement (2-3 hours)
- **Phase 6**: Documentation (1-2 hours)
- **Total**: 9-14 hours of development time 