cd # Game Balance Dashboard Implementation Plan

## Original Request
<user_query>
Progression Curve Visualizer would be a good start as I'm having issues with skill damage, weapon damage, armor defense.
Proper xp scaling has been an issue too as I feel chars are leveling too fast
from there, you could go for monster difficult scaling.

But before start, create a plan that we can go back to and mark our progress as we go. You can create it at @/planning and use .md as format
</user_query>

## Changelog
- 2024-01-XX: Initial plan creation for Game Balance Dashboard
- 2024-01-XX: **Phase 1 Week 1 COMPLETED** - Core balance analyzer engine created with progression curve calculation, skill efficiency analysis, equipment progression analysis, and XP scaling framework
- 2024-01-XX: **Phase 1 Week 1 COMPLETED** - Full interactive dashboard UI created with Chart.js visualizations and tabbed interface
- 2024-01-XX: **Phase 1 Week 1 COMPLETED** - Flask routes implemented for all balance analysis endpoints
- 2024-01-XX: **DATA PROCESSING COMPLETED** - Fixed data loading issues, implemented robust error handling, and completed all core data processing functions
- 2024-01-XX: **UI POPULATION FIXED** - Added proper job list population, error messaging, and debugging capabilities

---

## 1. Project Overview

### 1.1. Current Pain Points
- **Skill Damage Balance:** Difficulty assessing if skills are over/underpowered for their level and MP cost
- **Weapon Progression:** Unclear weapon damage scaling vs. character progression
- **Armor Effectiveness:** Defense values may not scale properly with expected damage
- **XP Scaling Issues:** Characters leveling too fast, disrupting intended progression pace
- **Monster Balance:** Need to evaluate monster difficulty vs. player power at different levels
- **Disconnected Data:** Balance decisions require jumping between multiple pages/files

### 1.2. Solution Goals
- **Unified Balance View:** Single dashboard showing all balance relationships
- **Visual Progression Curves:** Charts showing how all systems scale together
- **Automated Analysis:** Tools that identify potential balance issues
- **Quick Testing:** Rapid iteration tools for balance adjustments
- **Data-Driven Decisions:** Clear metrics to guide balance changes

### 1.3. Technical Approach
- **Extend existing Flask web tool** at `/dev/` for seamless integration
- **Interactive charts** using Chart.js or Plotly for visualization
- **Real-time calculations** based on actual game formulas
- **Export capabilities** for sharing analysis with team

---

## 2. Phase 1: Progression Curve Visualizer (Priority 1)

### 2.1. Core Features ✅ **COMPLETED**
- [x] **Character Power Progression Chart**
  - [x] Show effective attack power vs. character level for different job combinations
  - [x] Include weapon progression impact on total damage
  - [x] Factor in attribute growth and equipment requirements
  - [x] Display multiple build paths on same chart for comparison

- [x] **Skill Damage Analysis**
  - [x] Chart skill damage scaling vs. MP cost efficiency
  - [x] Compare skills across different levels and character builds
  - [x] Highlight outliers (over/underpowered skills)
  - [x] Show skill DPS vs. resource consumption

- [x] **Equipment Progression Curves**
  - [x] Weapon attack values vs. level requirements
  - [x] Armor defense values vs. level requirements
  - [x] Show gaps in equipment progression (missing tier items)
  - [x] Compare different equipment paths (STR vs DEX weapons, etc.)

- [x] **XP and Leveling Analysis**
  - [x] Current XP curve vs. intended progression pace
  - [x] Time-to-level calculations based on expected encounter rates
  - [x] Compare XP rewards vs. difficulty for different content types
  - [x] Identify XP inflation points

### 2.2. Technical Implementation

#### 2.2.1. Data Analysis Engine ✅ **COMPLETED**
- [x] **Create `balance_analyzer.py`**
  - [x] Parse all game data files (items, skills, jobs, monsters)
  - [x] Calculate effective damage formulas using actual game logic
  - [x] Generate progression data points for visualization
  - [x] Cache calculations for performance

- [x] **Extend `app.py`** with new routes:
  - [x] `/balance` - Main dashboard route
  - [x] `/balance/progression` - Character progression analysis
  - [x] `/balance/skills` - Skill balance analysis
  - [x] `/balance/equipment` - Equipment progression analysis
  - [x] `/balance/xp` - XP scaling analysis

#### 2.2.2. Frontend Components ✅ **COMPLETED**
- [x] **Create `templates/balance_dashboard.html`**
  - [x] Responsive layout with multiple chart sections
  - [x] Interactive filters (job selection, level ranges, etc.)
  - [x] Real-time chart updates based on filter changes
  - [x] Export functionality for charts and data

- [x] **Chart Implementation**
  - [x] Character power progression line charts
  - [x] Skill efficiency scatter plots
  - [x] Equipment tier progression charts
  - [x] XP curve comparison charts

#### 2.2.3. Data Processing Functions ✅ **COMPLETED**
- [x] **Character Power Calculator**
  ```python
  def calculate_character_power(level, job_combination, equipment_tier):
      # Factor in attribute growth, job bonuses, equipment stats
      # Return attack_power, magic_power, defense, etc.
  ```

- [x] **Skill Efficiency Analyzer**
  ```python
  def analyze_skill_efficiency(skill_data, character_stats):
      # Calculate damage per MP, DPS, utility value
      # Compare against baseline expectations
  ```

- [x] **XP Curve Analyzer**
  ```python
  def analyze_xp_scaling(current_xp_table, target_progression_hours):
      # Calculate actual vs. intended leveling pace
      # Identify problematic XP jumps
  ```

### 2.3. Balance Metrics and Calculations

#### 2.3.1. Character Power Metrics
- [x] **Effective Attack Power**
  - [x] Base STR + weapon attack + job bonuses
  - [x] Factor in hit rate and critical chance
  - [x] Account for dual-wield penalties/bonuses

- [x] **Effective Magic Power**
  - [x] Base INT + weapon magic attack + job bonuses
  - [x] Factor in elemental affinities
  - [x] Account for mana efficiency

- [x] **Survivability Index**
  - [x] HP pool (CON-based) + defense + magic defense
  - [x] Factor in evasion and damage reduction
  - [x] Account for healing capabilities

#### 2.3.2. Skill Balance Metrics
- [x] **Damage per MP Efficiency**
- [x] **DPS (Damage per Second) accounting for casting time**
- [x] **Utility Value Score** for non-damage skills
- [x] **Level-appropriate power scaling**

#### 2.3.3. Equipment Balance Metrics
- [x] **Power per Requirement Point** (attack/defense vs. stat requirements)
- [x] **Value per Gold Efficiency**
- [x] **Progression Gap Analysis** (missing equipment tiers)

### 2.4. User Interface Design
- [x] **Dashboard Layout**
  - [x] Navigation tabs for different analysis types
  - [x] Filter sidebar (job selection, level ranges, item tiers)
  - [x] Main chart area with zoom/pan capabilities
  - [x] Summary statistics panel
  - [x] Quick action buttons (export, refresh, settings)

- [x] **Interactive Features**
  - [x] Hover tooltips showing detailed calculations
  - [ ] Click-through to edit specific items/skills
  - [x] Comparison mode (overlay multiple builds)
  - [ ] Bookmark/save specific analysis views

---

## 3. Phase 2: Monster Difficulty Scaling (Priority 2)

### 3.1. Core Features
- [x] **Monster Power Progression**
  - [x] Chart monster HP, attack, defense vs. dungeon level (currently vs monster level)
  - [~] Compare monster scaling vs. expected player power
  - [~] Identify difficulty spikes or valleys
  - [x] Analyze special abilities impact on effective difficulty

- [x] **Encounter Balance Analysis**
  - [x] Expected TTK (Time to Kill) for monsters vs. player builds
  - [x] Player survivability vs. monster damage output
  - [x] XP reward appropriateness for monster difficulty
  - [~] Loot drop value vs. effort required

- [~] **Difficulty Curve Visualization** (In Progress)
  - [~] Show recommended vs. actual player level for content (In Progress)
  - [-] Highlight content that's too easy/hard for intended level
  - [-] Compare different party compositions vs. monster types

### 3.2. Technical Implementation
- [x] **Monster Analysis Engine**
  - [x] Parse monster definitions and calculate effective power
  - [x] Simulate combat scenarios with different player builds
  - [~] Generate difficulty ratings based on multiple factors (In Progress)

- [x] **Combat Simulation**
  - [x] Quick combat calculator for balance testing
  - [x] Average damage calculations (player vs. monster)
  - [x] Survivability projections
  - [-] Ability usage optimization

---

## 4. Phase 3: Advanced Balance Tools (Future)

### 4.1. Real-time Balance Testing
- [ ] **Live Combat Simulator**
  - [ ] Test character builds vs. specific monsters
  - [ ] Adjust values and see immediate impact
  - [ ] Compare multiple scenarios side-by-side

- [ ] **What-if Analysis Tools**
  - [ ] "What if this weapon had +2 attack?"
  - [ ] "What if this skill cost 2 less MP?"
  - [ ] Instant visualization of balance changes

### 4.2. Automated Balance Validation
- [ ] **Balance Alert System**
  - [ ] Flag items/skills that deviate significantly from curves
  - [ ] Warn about progression gaps or power spikes
  - [ ] Suggest automatic balance adjustments

- [ ] **Regression Testing**
  - [ ] Track balance changes over time
  - [ ] Compare current balance vs. previous versions
  - [ ] Ensure changes don't break existing progression

### 4.3. Advanced Analytics
- [ ] **Player Power Distribution**
  - [ ] Show how different build choices affect power curves
  - [ ] Identify dominant/weak strategies
  - [ ] Analyze build diversity and viability

- [ ] **Economic Balance**
  - [ ] Item value vs. player wealth progression
  - [ ] Shop prices vs. item effectiveness
  - [ ] Resource scarcity analysis

---

## 5. Implementation Roadmap

### 5.1. Phase 1 - Weeks 1-3
- [x] **Week 1: Data Analysis Foundation**
  - [x] Create balance_analyzer.py with core calculation functions
  - [x] Implement character power progression calculator
  - [x] Add basic chart generation capabilities
  - [x] Test with sample data

- [x] **Week 2: Skill and Equipment Analysis**
  - [x] Implement skill efficiency analyzer
  - [x] Add equipment progression analysis
  - [x] Create XP scaling analyzer
  - [x] Build interactive charts

- [x] **Week 3: Dashboard Integration**
  - [x] Create balance dashboard template
  - [x] Integrate all analyzers into Flask app
  - [x] Add filtering and interactivity
  - [x] Polish UI and add export features

### 5.2. Phase 2 - Weeks 4-5
- [x] **Week 4: Monster Analysis**
  - [x] Implement monster power calculator
  - [x] Add combat simulation engine
  - [x] Create monster difficulty charts

- [~] **Week 5: Encounter Balance** (Partially Done)
  - [x] Add encounter balance analysis
  - [x] Implement TTK calculations
  - [~] Create difficulty curve visualizations (In Progress)

### 5.3. Phase 3 - Future Expansion
- [ ] Advanced tools based on usage feedback
- [ ] Integration with game analytics
- [ ] Automated balance suggestions

---

## 6. Success Metrics

### 6.1. Immediate Goals (Phase 1)
- [x] **Clear visibility** into progression curves across all systems
- [x] **Quick identification** of balance outliers
- [x] **Reduced time** to make informed balance decisions
- [x] **Confidence** in balance changes through data visualization

### 6.2. Long-term Goals
- [ ] **Automated detection** of balance issues
- [ ] **Predictive modeling** for balance changes
- [ ] **Player feedback integration** with balance data
- [ ] **Continuous balance monitoring** and adjustment

---

## 7. Technical Requirements

### 7.1. Dependencies
- [ ] Chart.js or Plotly.js for interactive charts
- [ ] NumPy/Pandas for data analysis (if needed)
- [ ] Additional Flask routes and templates
- [ ] CSS framework updates for dashboard layout

### 7.2. Data Sources
- [ ] All existing Lua data files (items, skills, jobs, monsters)
- [ ] Game formula implementations
- [ ] Expected progression targets (to be defined)

### 7.3. Performance Considerations
- [ ] Cache calculated progression data
- [ ] Optimize chart rendering for large datasets
- [ ] Implement progressive loading for complex analyses

---

## 8. Future Enhancements

### 8.1. Integration Possibilities
- [ ] **Live Game Data:** Connect to game logs for real player data
- [ ] **A/B Testing:** Compare different balance configurations
- [ ] **Player Feedback:** Integrate community balance feedback
- [ ] **Automated Testing:** Run balance validation on code changes

### 8.2. Advanced Features
- [ ] **Machine Learning:** Predict optimal balance points
- [ ] **Scenario Planning:** Model long-term progression implications
- [ ] **Multi-game Analysis:** Compare with similar game balance curves
- [ ] **Dynamic Balancing:** Real-time balance adjustments based on player data

---

## 9. Risk Mitigation

### 9.1. Technical Risks
- [ ] **Performance:** Large dataset visualization may be slow
  - *Mitigation:* Implement data sampling and progressive loading
- [ ] **Accuracy:** Calculation errors could mislead balance decisions
  - *Mitigation:* Thorough testing against actual game mechanics
- [ ] **Maintenance:** Complex dashboard may be hard to maintain
  - *Mitigation:* Modular design and comprehensive documentation

### 9.2. Design Risks
- [ ] **Information Overload:** Too many charts may confuse rather than clarify
  - *Mitigation:* Progressive disclosure and clear navigation
- [ ] **False Precision:** Charts may suggest more accuracy than data supports
  - *Mitigation:* Clear uncertainty indicators and caveats

---

## 10. Documentation Requirements

### 10.1. Technical Documentation
- [ ] API documentation for balance analysis functions
- [ ] Chart configuration and customization guide
- [ ] Data flow and calculation methodology
- [ ] Performance optimization guidelines

### 10.2. User Documentation
- [ ] Dashboard user guide with screenshots
- [ ] Balance analysis interpretation guide
- [ ] Best practices for using balance data
- [ ] Troubleshooting common issues

---

*This plan will be updated as development progresses and requirements evolve.* 