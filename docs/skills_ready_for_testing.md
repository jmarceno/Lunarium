# Skills Ready for Testing - Phase 3 Complete

This document lists all the skills that now have fully implemented advanced mechanics and are ready for testing.

## Phase 1 Skills ✅ (Core Combat Mechanics)

### Execute/Health-Based Damage
- **VitalStrike** - Damage scales with target's missing health
- **Execution** - Instant kill below 25% health threshold  
- **RighteousStrike** - Damage scales with user's current health

### Stealth System
- **Backstab** - Requires stealth status, breaks stealth on use, high crit damage
- **Vanish** - Applies stealth + untargetable status
- **PoisonBlade** - Coats weapon with poison for ongoing damage

## Phase 2 Skills ✅ (Advanced Combat Features)

### Complex Accuracy/Dodge
- **PreciseShot** - Never misses regardless of accuracy
- **QuickDraw** - +20 accuracy bonus, instant casting
- **HawkEye** - Status effect: +25% accuracy and crit chance
- **Frenzy** - 5-hit attack with 20% accuracy decay per hit
- **Bloodlust** - +40% damage but accuracy penalty

### Self-Affecting Mechanics
- **BrutalSwing** - Massive damage but stuns self (duration reduces with level)

### Guardian/Protection Systems
- **GuardianStance** - 30% damage reduction stance (scales with level)

## Phase 3 Skills ✅ (Special Effect Systems)

### Revival/Resurrection
- **Revive** - Brings back fallen allies with 30-80% health (scales with level)

### Multi-Element/Chaos Effects
- **ElementalConversion** - Converts 50-90% elemental damage to MP
- **DimensionalRift** - Triggers 3-7 random chaos effects (damage, healing, status, element change)

### Trap and Environmental Effects
- **TrapMastery** - 2x damage vs beasts, 1.8x vs monsters, 1.5x vs animals
- **Consecration** - Creates holy ground that damages undead each turn

### Time Manipulation
- **TimeStop** - Slows all enemies by 80% for 3-8 turns (respects turn system)

## Testing Scenarios

### Basic Function Tests
1. **Execute Mechanics**: Test VitalStrike and Execution on low-health enemies
2. **Stealth**: Use Vanish, then Backstab to verify stealth requirement
3. **Accuracy**: Use Frenzy to see accuracy decay, HawkEye for bonuses
4. **Revival**: Defeat an ally, then use Revive to bring them back
5. **Time Stop**: Use TimeStop and verify enemies move much slower

### Advanced Interaction Tests
1. **Stealth + Execute**: Vanish → Backstab on low-health target for massive damage
2. **Chaos Effects**: Use DimensionalRift multiple times to see variety of effects
3. **Environmental**: Use Consecration against undead vs non-undead enemies
4. **Elemental Conversion**: Cast ElementalConversion, then take elemental damage

### Edge Case Tests
1. **Full Health Execute**: Test Execution on full-health enemies (should not instant kill)
2. **Stealth Breaking**: Verify Backstab removes stealth after use
3. **Self-Stun Scaling**: Test BrutalSwing at different skill levels
4. **Revival Turn Order**: Verify revived allies get proper turn order

## Debug Mode Recommendations

Enable `GAME.debug = true` to see:
- Health percentage calculations for execute skills
- Elemental conversion MP amounts
- Creature type bonus multipliers
- Chaos effect selections
- Stealth damage bonus applications

## Known Interactions

### Positive Stacking
- Stealth damage bonus + Execute damage bonus = Very high damage
- HawkEye accuracy + QuickDraw accuracy = Nearly guaranteed hits
- Multiple status effects can stack appropriately

### Working as Intended
- TimeStop respects active turn system (doesn't break turn order)
- Consecration only damages undead (harmless to other types)
- Backstab requires stealth (prevents use without Vanish first)
- BrutalSwing self-stun duration decreases with skill level

## Performance Notes

All new mechanics have been optimized for:
- No memory leaks from status effects
- Efficient creature type checking
- Minimal impact on existing combat performance
- Proper cleanup when effects expire

---

**Status: All Phases Complete - Ready for User Testing**

Test any combination of these skills to verify the advanced mechanics are working correctly. The implementation maintains full backward compatibility, so existing skills continue to work unchanged. 