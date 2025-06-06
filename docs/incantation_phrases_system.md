# Incantation Phrases System Documentation

## Overview

The Incantation Phrases System adds immersive speech bubbles that appear above character portraits during spell casting in combat. As characters cast spells with casting times greater than 1 second, they will speak incantation phrases that accumulate in speech bubbles, creating a more engaging and atmospheric combat experience.

## Features

- **Additive Phrase Display**: Phrases accumulate in speech bubbles as casting progresses
- **Timing-Based Progression**: Phrases appear at regular intervals during casting
- **Post-Cast Retention**: Speech bubbles remain visible for 2 seconds after spell completion
- **Multi-line Support**: Speech bubbles automatically handle line breaks and text wrapping
- **Auto-sizing**: Bubbles resize based on accumulated text content
- **Visual Integration**: Bubbles position above character slots with automatic boundary detection

## Technical Implementation

### Core Components

1. **Speech Bubble Module** (`screens/ui_slices/speechBubble.lua`)
   - Handles bubble drawing, text wrapping, and positioning
   - Supports multi-line text with automatic line breaks
   - Auto-calculates bubble dimensions based on content

2. **Incantation Timing System** (`gameplay/combat/coreFunctions.lua`)
   - Manages phrase progression during spell casting
   - Handles phrase accumulation and timing distribution
   - Controls post-cast display duration

3. **UI Integration** (`screens/ui_slices/partyPanel.lua`)
   - Integrates speech bubbles into combat party panel
   - Accesses spell queue for active incantations
   - Positions bubbles above character slots with boundary awareness
   - Implements adaptive sizing based on available slot space

### Data Structure

Each spell queue entry now includes incantation-specific fields:

```lua
{
    -- Existing fields...
    incantationPhrases = skill.incantationPhrases or {},
    currentPhraseIndex = 0,
    phrasesShown = {},
    accumulatedText = "",
    phraseDisplayTime = 0,
    lastPhraseShown = false,
    postCastDisplayTimer = 0,
    isPostCast = false
}
```

### Phrase Timing Logic

- **Single Phrase**: Displays immediately when casting begins
- **Multiple Phrases**: Distributed evenly across total casting time
- **Completion Guarantee**: All phrases are visible when spell completes
- **Post-Cast Display**: Bubbles remain for 2 seconds after casting

## Adding Incantations to Skills

### Skill Definition Format

Add the `incantationPhrases` field to any skill with `castingTime > 1`:

```lua
SkillName = {
    name = "Skill Name",
    -- ... other properties ...
    castingTime = 2, -- Must be > 1 for incantations
    incantationPhrases = {
        "First phrase spoken during casting...",
        "Second phrase as casting progresses...",
        "Final phrase when spell completes!"
    },
    -- ... rest of skill definition ...
}
```

### Content Guidelines

**Magical Spells**: Use mystical, arcane language
```lua
incantationPhrases = {
    "I call upon the flames of destruction...",
    "Let fire consume my enemies!"
}
```

**Physical Abilities**: Use battle cries or technique names
```lua
incantationPhrases = {
    "For honor and glory!",
    "Take this!"
}
```

**Healing Spells**: Use prayers or healing words
```lua
incantationPhrases = {
    "By the light that binds us...",
    "Let healing energy flow through me...",
    "Restore what was broken!"
}
```

**Utility/Support**: Use focused commands
```lua
incantationPhrases = {
    "By the power of my will...",
    "Shield me with arcane force!"
}
```

## Current Implementation Status

### Skills with Incantation Phrases

- **FireBolt** (2s casting): Fire destruction incantations
- **ThunderBolt** (2s casting): Storm and lightning calls
- **Fireball** (3s casting): Extended fire magic ritual
- **ManaShield** (2s casting): Protective barrier incantations
- **GroupHeal** (3s casting): Extended healing prayers
- **SummonBallista** (3s casting): Mechanical construction commands
- **BallistaRepair** (2s casting): Repair and restoration phrases
- **BallistaOvercharge** (2s casting): Power enhancement commands

### Phrase Distribution Examples

**2-Second Spells** (2 phrases):
- Phrase 1: Appears at 0-1 seconds
- Phrase 2: Appears at 1-2 seconds
- Both visible when spell completes

**3-Second Spells** (3 phrases):
- Phrase 1: Appears at 0-1 seconds  
- Phrase 2: Appears at 1-2 seconds
- Phrase 3: Appears at 2-3 seconds
- All three visible when spell completes

## Visual Behavior

### Speech Bubble Appearance

- **Background**: Light gray with rounded corners
- **Border**: Darker gray outline
- **Tail**: Points to character, positioned within bubble bounds
- **Text**: Dark text, centered in bubble
- **Positioning**: Above character slot, slot-boundary aware
- **Adaptive Sizing**: Dynamically sized based on available character slot space

### Text Handling

- **Line Breaks**: Automatic on `\n` characters
- **Wrapping**: Respects dynamic maximum bubble width (up to 300px or slot width)
- **Spacing**: 2px between lines for readability
- **Centering**: Text centered horizontally in bubble
- **Boundary Awareness**: Bubbles stay within character slot boundaries

### Animation States

1. **Casting**: Phrases accumulate as casting progresses
2. **Complete**: All phrases visible, spell executes
3. **Post-Cast**: Bubble remains for 2 seconds
4. **Cleanup**: Bubble disappears, spell removed from queue

## Performance Considerations

- **Efficient Text Measurement**: Cached font metrics with real-time size calculation
- **Minimal Memory Usage**: Phrases stored only during casting
- **Optimized Rendering**: Bubbles drawn only for active casters
- **Automatic Cleanup**: Post-cast timers prevent memory leaks
- **Smart Positioning**: Boundary calculations performed only during active casting

## Positioning System

### Slot-Based Positioning

The speech bubble system uses intelligent positioning that considers each character's allocated space in the party panel:

- **Slot Center Alignment**: Bubbles center on the character's entire slot rather than just the portrait
- **Dynamic Width Calculation**: Maximum bubble width is determined by available slot space (up to 300px)
- **Boundary Enforcement**: Bubbles are constrained to stay within their character's slot boundaries
- **Edge Character Handling**: Characters at panel edges receive adjusted positioning to prevent overflow

### Positioning Algorithm

```lua
-- Calculate character slot center and boundaries
local slotCenterX = x + width / 2
local leftBound = x + 10  -- Slot left edge with margin
local rightBound = x + width - 10  -- Slot right edge with margin

-- Determine optimal bubble width based on available space
local availableWidth = width - 20
local maxBubbleWidth = math.min(300, availableWidth)

-- Calculate actual bubble dimensions
local bubbleWidth, _ = speechBubble:calculateSize(text, maxBubbleWidth, font)

-- Adjust position to ensure bubble stays within slot bounds
if bubbleX - bubbleWidth/2 < leftBound then
    bubbleX = leftBound + bubbleWidth/2
elseif bubbleX + bubbleWidth/2 > rightBound then
    bubbleX = rightBound - bubbleWidth/2
end
```

This ensures optimal visual presentation regardless of character position or phrase length.

## Integration Points

### Combat System Integration

The party panel receives a reference to the combat system:
```lua
partyPanel.combatSystem = self -- Provides access to spell queue
```

### Spell Queue Access

Speech bubbles access active spells through:
```lua
if self.combatSystem and self.combatSystem.spellQueue then
    for _, spell in ipairs(self.combatSystem.spellQueue) do
        -- Check for active incantations
    end
end
```

## Future Enhancements

### Potential Improvements

1. **Audio Integration**: Voice acting or sound effects for phrases
2. **Localization Support**: Translation system for multiple languages
3. **Visual Effects**: Particle effects synchronized with phrases
4. **Customization**: Player-configurable phrase display options
5. **Non-Combat Usage**: Incantations in town healing or other contexts

### Scalability Considerations

- **Content Management**: Integration with content management dashboard
- **Phrase Validation**: Automatic checking for appropriate phrase counts
- **Performance Monitoring**: Tracking bubble rendering performance
- **Memory Management**: Optimization for large numbers of simultaneous casters

## Troubleshooting

### Common Issues

**Bubbles Not Appearing**:
- Verify skill has `castingTime > 1`
- Check `incantationPhrases` field exists
- Ensure combat system reference is passed to party panel

**Text Overlap**:
- Bubbles are automatically constrained to character slot boundaries
- Maximum bubble width adapts to available space per character
- Positioning automatically adjusts to prevent off-screen overflow

**Timing Issues**:
- Verify phrase interval calculations
- Check post-cast timer duration (2 seconds)
- Ensure phrase accumulation logic is correct

**Performance Problems**:
- Monitor bubble count during large battles
- Check text measurement efficiency
- Verify proper cleanup after spell completion

## API Reference

### speechBubble Module

```lua
speechBubble:draw(text, x, y, maxWidth, characterIndex)
speechBubble:calculateSize(text, maxWidth, font)
speechBubble:splitLines(text)
```

### Incantation Functions

```lua
updateIncantationPhrases(spell, dt)  -- Internal timing logic
```

### Integration Methods

```lua
partyPanel.combatSystem = combatSystem  -- Reference passing
partyPanel:setCombatMode(true, party)   -- Combat mode setup
```

## Version History

- **v1.0**: Initial implementation with core functionality
- **v1.1**: Added post-cast display retention
- **v1.2**: Improved text wrapping and bubble sizing
- **v1.3**: Enhanced phrase timing distribution
- **v1.4**: Improved positioning with slot-boundary awareness and adaptive sizing

---

*This documentation covers the complete Incantation Phrases System implementation. For technical support or feature requests, refer to the main project documentation.* 