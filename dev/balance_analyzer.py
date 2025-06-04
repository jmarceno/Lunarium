"""
Game Balance Analyzer
Core engine for analyzing game balance across progression curves, skills, equipment, and experience scaling.
"""

import os
import math
import json
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional
# from app import LuaTableManager # Old import
from lua_utils import LuaTableManager # New import

class BalanceAnalyzer:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.data_path = project_root / 'data'
        self.lua_manager = LuaTableManager()
        
        # Cache for loaded data
        self._cache = {}
        
        # Balance constants (can be adjusted for tuning)
        self.BASE_ATTRIBUTES = {
            'STR': 10, 'INT': 10, 'CON': 10, 
            'WIL': 10, 'CHA': 10, 'DEX': 10, 'WIS': 10
        }
        self.ATTRIBUTE_GROWTH_PER_LEVEL = 2  # Points gained per level
        self.BASE_ATTRIBUTE_CAP = 50
        # Assumed cap for how many levels a specific job's attributeModifier provides benefit
        self.JOB_MODIFIER_LEVEL_CAP = 10 

    def _load_data_file(self, filename: str) -> Dict:
        """Load and cache data from a Lua file."""
        if filename not in self._cache:
            file_path = self.data_path / filename
            if file_path.exists():
                try:
                    data = self.lua_manager.read_lua_file(file_path)
                    # Ensure top-level data is a dict, especially for files returning a single table
                    if isinstance(data, list) and filename == 'job_definitions.lua': # Special handling if jobs are list
                        print(f"Warning: {filename} loaded as list, attempting to find main table.")
                        # This case should ideally be handled by LuaTableManager returning the main dict
                        # For now, if it's a list of jobs, we might need to rethink or ensure LuaTableManager handles it.
                        # Assuming LuaTableManager correctly extracts the 'jobDefinitions' table or similar.
                        pass # Keep as is, assuming lua_manager gives dict
                    
                    self._cache[filename] = data if data is not None else {}
                    #print(f"Loaded {filename}: {len(self._cache[filename]) if isinstance(self._cache[filename], dict) else 'N/A'} items. Type: {type(self._cache[filename])}")
                except Exception as e:
                    print(f"Error loading {filename}: {e}")
                    self._cache[filename] = {}
            else:
                print(f"Warning: {filename} not found")
                self._cache[filename] = {}
        return self._cache[filename]
    
    def get_jobs_data(self) -> Dict:
        """Get job definitions."""
        data = self._load_data_file('job_definitions.lua')
        # job_definitions.lua returns a table like: local jobDefinitions = { Fighter = {...}, ... }
        # So, if 'jobDefinitions' is a key, use that, otherwise assume data is the dict of jobs.
        return data.get('jobDefinitions', data) # Access the 'jobDefinitions' table if present
    
    def get_skills_data(self) -> Dict:
        """Get skill definitions."""
        data = self._load_data_file('skill_definitions.lua')
        return data.get('skillDefinitions', data)
    
    def get_items_data(self) -> Dict:
        """Get item definitions."""
        data = self._load_data_file('item_definitions.lua')
        # item_definitions.lua might have RARITY and items. We need 'items'.
        if 'items' in data:
             return data['items']
        elif 'itemDefinitions' in data and 'items' in data['itemDefinitions']: # another possible structure
             return data['itemDefinitions']['items']
        return data # Fallback, though likely needs 'items' key
    
    def get_monsters_data(self) -> Dict:
        """Get monster definitions."""
        data = self._load_data_file('monster_definitions.lua')
        return data.get('monsters', data.get('monsterDefinitions', data))

    def get_monster_abilities_data(self) -> Dict:
        """Get monster ability definitions."""
        data = self._load_data_file('monsterAbilities.lua')
        # monsterAbilities.lua returns a table like: local monsterAbilities = { definitions = { ... } }
        return data.get('definitions', data) # Access the 'definitions' table

    def get_skills_for_job(self, job_id: str) -> Dict:
        """Get all skills (starting and available) for a specific job."""
        jobs_data = self.get_jobs_data()
        all_skills_data = self.get_skills_data()
        
        job_info = jobs_data.get(job_id)
        if not job_info or not isinstance(job_info, dict): # Ensure job_info is a dict
            print(f"Warning: Job ID '{job_id}' not found or invalid in job_definitions.lua")
            return {}
            
        job_skill_names = set()
        for skill_list_key in ['startingSkills', 'availableSkills']:
            skills = job_info.get(skill_list_key)
            if isinstance(skills, dict): # Lua array might be dict with numeric keys
                job_skill_names.update(skills.values())
            elif isinstance(skills, list):
                job_skill_names.update(skills)
        
        job_specific_skills = {}
        for skill_name in job_skill_names:
            if skill_name in all_skills_data:
                job_specific_skills[skill_name] = all_skills_data[skill_name]
            else:
                print(f"Warning: Skill '{skill_name}' for job '{job_id}' not in skill_definitions.lua")
        return job_specific_skills
    
    def _parse_job_requirements(self, job_data: Dict) -> Optional[Dict[str, int]]:
        reqs = job_data.get('requirements')
        if isinstance(reqs, dict) and reqs:
            # Ensure values are integers
            parsed_reqs = {}
            valid_reqs = True
            for job_name, level in reqs.items():
                try:
                    parsed_reqs[job_name] = int(level)
                except (ValueError, TypeError):
                    print(f"Warning: Invalid level '{level}' for requirement '{job_name}' in job '{job_data.get('name', 'Unknown Job')}'. Skipping requirement.")
                    valid_reqs = False # Or handle more strictly
                    # For now, let's allow partial valid reqs
            return parsed_reqs if parsed_reqs else None # only return if any valid reqs were parsed
        return None

    def _build_job_progression_path(self, target_job_id: str, total_char_level: int, all_jobs_data: Dict, _visited_jobs: Optional[set] = None) -> List[Tuple[str, int, int]]:
        # Returns list of (job_id, levels_in_this_job_segment, cumulative_level_at_end_of_segment)
        
        _visited_jobs = _visited_jobs or set()
        if target_job_id in _visited_jobs:
            print(f"Error: Circular job dependency detected involving {target_job_id}")
            return []
        _visited_jobs.add(target_job_id)

        current_job_data = all_jobs_data.get(target_job_id)
        if not current_job_data:
            print(f"Error: Job data for '{target_job_id}' not found during path building.")
            _visited_jobs.remove(target_job_id)
            return []

        requirements = self._parse_job_requirements(current_job_data)
        
        base_path = []
        entry_level_for_current_job = 0 # Level at which current_job_id is entered

        if requirements:
            # Find the main prerequisite (highest level requirement)
            # This simplification assumes a linear progression path for prerequisites
            main_prereq_job_id = None
            highest_req_level = 0
            for req_job, req_level in requirements.items():
                if req_level > highest_req_level:
                    highest_req_level = req_level
                    main_prereq_job_id = req_job
            
            if main_prereq_job_id:
                if total_char_level < highest_req_level:
                    # Not high enough for this job's prereqs, try to build path for the prereq job instead
                    # using the current total_char_level.
                    # Pass a copy of visited_jobs for the new recursive branch
                    path = self._build_job_progression_path(main_prereq_job_id, total_char_level, all_jobs_data, _visited_jobs.copy())
                    _visited_jobs.remove(target_job_id) # Backtrack current job from visited for this path
                    return path

                # Build path for the prerequisite up to its required level
                # Pass a copy of visited_jobs for the new recursive branch
                base_path = self._build_job_progression_path(main_prereq_job_id, highest_req_level, all_jobs_data, _visited_jobs.copy())
                if not base_path: # Prerequisite path failed
                    _visited_jobs.remove(target_job_id)
                    return [] 
                entry_level_for_current_job = highest_req_level
        
        levels_in_current_job_segment = total_char_level - entry_level_for_current_job
        
        if levels_in_current_job_segment < 0:
            # This means total_char_level was not enough for this job, but it might have been enough for its prereqs.
            # The base_path (prereqs) is the actual path in this case.
            _visited_jobs.remove(target_job_id)
            return base_path

        # Append current job segment to the base_path (which could be empty if no prereqs)
        current_segment_path = base_path
        # Ensure levels_in_current_job_segment is not negative before appending
        # (already handled by check above, but good for clarity)
        current_segment_path.append((target_job_id, levels_in_current_job_segment, total_char_level))
        
        _visited_jobs.remove(target_job_id)
        return current_segment_path

    def calculate_character_attributes(self, final_job_id: str, total_char_level: int) -> Dict[str, int]:
        attributes = self.BASE_ATTRIBUTES.copy()
        all_jobs_data = self.get_jobs_data()

        if final_job_id not in all_jobs_data:
            print(f"Warning: Job '{final_job_id}' not found. Calculating attributes for base stats at level {total_char_level}.")
        
        job_path = self._build_job_progression_path(final_job_id, total_char_level, all_jobs_data)

        if not job_path:
            # Path construction failed or character doesn't meet any job requirements at this level.
            # Fallback to base attributes + generic level points.
            print(f"Could not build job path for '{final_job_id}' L{total_char_level}. Using base stats + generic points.")
            # Apply generic attribute points
            points_to_distribute = total_char_level * self.ATTRIBUTE_GROWTH_PER_LEVEL
            if points_to_distribute > 0 and attributes:
                # Simplified even distribution for this fallback case
                points_per_attr = points_to_distribute // len(attributes)
                remainder = points_to_distribute % len(attributes)
                attr_keys = list(attributes.keys())
                for i, key in enumerate(attr_keys):
                    attributes[key] += points_per_attr + (1 if i < remainder else 0)
            for attr_key in attributes: # Apply caps
                attributes[attr_key] = min(attributes[attr_key], self.BASE_ATTRIBUTE_CAP)
            return attributes

        # Apply job-specific attributeModifiers from each job in the path
        for job_id_segment, levels_in_segment, _ in job_path:
            job_segment_data = all_jobs_data.get(job_id_segment)
            if not job_segment_data or not isinstance(job_segment_data, dict):
                continue

            job_modifiers = job_segment_data.get('attributeModifiers')
            if isinstance(job_modifiers, dict):
                for attr, modifier_val in job_modifiers.items():
                    if attr in attributes:
                        # Benefit from modifier for levels in this segment, capped by JOB_MODIFIER_LEVEL_CAP
                        effective_levels_for_mod = min(levels_in_segment, self.JOB_MODIFIER_LEVEL_CAP)
                        attributes[attr] += modifier_val * effective_levels_for_mod
            else:
                 print(f"Warning: attributeModifiers for job {job_id_segment} is not a dictionary: {job_modifiers}")


        # Apply generic attribute points based on TOTAL character level, distributed intelligently
        points_to_distribute = total_char_level * self.ATTRIBUTE_GROWTH_PER_LEVEL
        
        # Intelligent distribution based on the *final* job's primary attributes
        final_job_data_for_dist = all_jobs_data.get(job_path[-1][0]) if job_path else None
        primary_attr_preferences = {}
        if final_job_data_for_dist and isinstance(final_job_data_for_dist.get('attributeModifiers'), dict):
            primary_attr_preferences = final_job_data_for_dist.get('attributeModifiers',{})

        if primary_attr_preferences and points_to_distribute > 0:
            # Sort attributes by modifier strength in the final job to prioritize
            sorted_pref_attrs = sorted(primary_attr_preferences.items(), key=lambda item: item[1], reverse=True)
            
            # Distribute more to preferred attributes
            for attr, _ in sorted_pref_attrs:
                if points_to_distribute == 0: break
                # Give a portion to primary stats, ensure at least 1 if possible
                boost = min(points_to_distribute, max(1, points_to_distribute // (len(sorted_pref_attrs) + 1) +1 ) ) # crude heuristic
                attributes[attr] += boost
                points_to_distribute -= boost
        
        # Distribute any remaining points evenly
        if points_to_distribute > 0 and attributes:
            base_points_per_attr = points_to_distribute // len(attributes)
            remainder_points = points_to_distribute % len(attributes)
            
            attr_keys_list = list(attributes.keys()) # Ensure consistent order for remainder
            for i, attr_key in enumerate(attr_keys_list):
                attributes[attr_key] += base_points_per_attr
                if i < remainder_points:
                    attributes[attr_key] += 1
        
        # Apply attribute caps
        for attr_key in attributes:
            attributes[attr_key] = min(attributes[attr_key], self.BASE_ATTRIBUTE_CAP)
            
        return attributes
    
    def calculate_character_power(self, level: int, job: str, equipment_tier: str = "basic") -> Dict[str, float]:
        """Calculate character's effective power metrics."""
        try:
            attributes = self.calculate_character_attributes(job, level)
            
            # Get typical equipment for this tier and level
            equipment = self._get_equipment_for_tier_and_level(equipment_tier, level, attributes)
            
            # Calculate attack power (STR + weapon attack)
            attack_power = attributes.get('STR', 10)
            weapon = equipment.get('weapon')
            if weapon:
                attack_power += weapon.get('attack', 0)
            
            # Calculate magic power (INT + weapon magic attack)
            magic_power = attributes.get('INT', 10)
            if weapon:
                magic_power += weapon.get('magicAttack', 0)
            
            # Calculate defense (CON-based + armor)
            defense = max(1, math.floor(attributes.get('CON', 10) / 2))
            for slot, item in equipment.items():
                if item and item.get('defense'):
                    defense += item['defense']
            
            # Calculate magic defense (WIL-based + armor)
            magic_defense = max(1, math.floor(attributes.get('WIL', 10) / 2))
            for slot, item in equipment.items():
                if item and item.get('magicDefense'):
                    magic_defense += item['magicDefense']
            
            # Calculate HP (CON-based)
            hp = 50 + (attributes.get('CON', 10) * 5)  # Base HP + CON scaling
            
            # Calculate MP (INT + WIS based)
            mp = 20 + (attributes.get('INT', 10) * 3) + (attributes.get('WIS', 10) * 2)
            
            # Calculate survivability index (composite metric)
            survivability = hp + (defense * 5) + (magic_defense * 3)
            
            return {
                'level': level,
                'job': job,
                'attributes': attributes,
                'attack_power': float(attack_power),
                'magic_power': float(magic_power),
                'defense': float(defense),
                'magic_defense': float(magic_defense),
                'hp': float(hp),
                'mp': float(mp),
                'survivability': float(survivability),
                'equipment': equipment
            }
        except Exception as e:
            print(f"Error calculating character power for {job} level {level}: {e}")
            # Return default values to prevent crashes
            return {
                'level': level,
                'job': job,
                'attributes': self.BASE_ATTRIBUTES.copy(),
                'attack_power': 15.0,
                'magic_power': 15.0,
                'defense': 8.0,
                'magic_defense': 8.0,
                'hp': 100.0,
                'mp': 50.0,
                'survivability': 150.0,
                'equipment': {}
            }
    
    def _get_equipment_for_tier_and_level(self, tier: str, level: int, char_attributes: Optional[Dict[str, int]] = None) -> Dict[str, Dict]:
        """Get appropriate equipment for a given tier and level."""
        items_data = self.get_items_data()
        equipment = {}
        # This function can be enhanced to consider char_attributes for meeting item requirements.
        # For now, tier mapping is simplified.
        tier_level_map = {'basic': (1, 10), 'intermediate': (11, 20), 'advanced': (21, 50)}
        min_lvl_req, max_lvl_req = tier_level_map.get(tier, (1,10))

        # Simplified: find best weapon/armor loosely based on level tier, not explicit attribute reqs yet
        # This needs to be more robust to use char_attributes to check item.requirements
        
        # Weapon
        best_weapon = None; best_weapon_power = -1
        for item_id, item in items_data.items():
            if item.get('type') == 'weapon':
                # Basic check for level appropriateness (e.g. item value or a new 'level' field on items)
                # For now, let's use a placeholder logic or assume items are generally tiered
                item_value = item.get('value',0) # crude proxy for level
                if not (min_lvl_req*10 <= item_value <= max_lvl_req*20 or tier == 'any'): # very loose
                     # This logic needs improvement, ideally items have level reqs or stat reqs we check against char_attributes
                     pass # continue

                power = item.get('attack', 0) + item.get('magicAttack', 0)
                if power > best_weapon_power:
                    best_weapon = item.copy(); best_weapon['item_id'] = item_id; best_weapon_power = power
        if best_weapon: equipment['weapon'] = best_weapon

        # Armor (Body)
        best_armor = None; best_armor_defense = -1
        for item_id, item in items_data.items():
            if item.get('type') == 'armor' and item.get('slot') == 'body':
                item_value = item.get('value',0)
                if not (min_lvl_req*10 <= item_value <= max_lvl_req*20 or tier == 'any'):
                    pass # continue
                
                defense_val = item.get('defense', 0) + item.get('magicDefense', 0)
                if defense_val > best_armor_defense:
                    best_armor = item.copy(); best_armor['item_id'] = item_id; best_armor_defense = defense_val
        if best_armor: equipment['body'] = best_armor
            
        return equipment
    
    def analyze_skill_efficiency(self, skill_id: str, character_stats: Dict) -> Dict[str, float]:
        """Analyze skill efficiency metrics."""
        skills_data = self.get_skills_data()
        skill = skills_data.get(skill_id, {})
        
        if not skill:
            return {}
        
        mp_cost = skill.get('mpCost', 0)
        base_power = skill.get('basePower', 0)
        skill_type = skill.get('type', 'physical')
        
        # Calculate effective damage based on character stats
        if skill_type == 'physical':
            effective_power = base_power + character_stats.get('attack_power', 0) * 0.5
        elif skill_type in ['magical', 'magic']:
            effective_power = base_power + character_stats.get('magic_power', 0) * 0.5
        else:
            # For support/utility skills, use base power
            effective_power = base_power if base_power > 0 else 50  # Default utility value
        
        # Apply level modifier if it exists (skip for now - too complex for initial implementation)
        
        # Calculate efficiency metrics
        damage_per_mp = effective_power / max(mp_cost, 1)  # Avoid division by zero
        
        # Estimate DPS based on casting time
        cast_time = skill.get('castingTime', 3.0)
        if cast_time <= 0:
            cast_time = 1.0  # Instant cast = 1 second equivalent
        dps = effective_power / cast_time
        
        # Calculate utility value (enhanced analysis)
        utility_value = 1.0
        if skill.get('effect'):
            utility_value = 1.5  # Bonus for skills with special effects
        if skill_type in ['support', 'utility']:
            utility_value = 1.3  # Support skills have inherent utility
        if skill.get('hits', 1) > 1:
            utility_value *= 1.2  # Multi-hit skills are more valuable
        
        return {
            'skill_id': skill_id,
            'name': skill.get('name', skill_id),
            'mp_cost': mp_cost,
            'effective_power': effective_power,
            'damage_per_mp': damage_per_mp,
            'dps': dps,
            'utility_value': utility_value,
            'skill_type': skill_type,
            'cast_time': cast_time
        }
    
    def analyze_equipment_progression(self) -> List[Dict]:
        """Analyze equipment progression curves."""
        items_data = self.get_items_data()
        progression_data = []
        
        for item_id, item in items_data.items():
            if item.get('type') in ['weapon', 'armor']:
                requirements = item.get('requirements', {})
                if not requirements:
                    max_requirement = 0
                else:
                    max_requirement = max(requirements.values()) if requirements.values() else 0
                
                # Calculate power metrics
                if item.get('type') == 'weapon':
                    attack = item.get('attack', 0)
                    magic_attack = item.get('magicAttack', 0)
                    power = attack + magic_attack * 0.8  # Weight magic attack slightly less
                    power_type = 'attack'
                else:  # armor
                    defense = item.get('defense', 0)
                    magic_defense = item.get('magicDefense', 0)
                    power = defense + magic_defense * 0.6  # Weight magic defense less
                    power_type = 'defense'
                
                # Calculate efficiency metrics
                value = item.get('value', 1)
                power_per_gold = power / max(value, 1)
                power_per_requirement = power / max(max_requirement, 1)
                
                progression_data.append({
                    'item_id': item_id,
                    'name': item.get('name', item_id),
                    'type': item.get('type'),
                    'slot': item.get('slot', 'unknown'),
                    'subType': item.get('subType', ''),
                    'max_requirement': max_requirement,
                    'power': power,
                    'power_type': power_type,
                    'value': value,
                    'power_per_gold': power_per_gold,
                    'power_per_requirement': power_per_requirement,
                    'requirements': requirements,
                    'attack': item.get('attack', 0),
                    'magicAttack': item.get('magicAttack', 0),
                    'defense': item.get('defense', 0),
                    'magicDefense': item.get('magicDefense', 0)
                })
        
        return sorted(progression_data, key=lambda x: x['max_requirement'])
    
    def analyze_xp_scaling(self, target_hours_per_level: float = 2.0) -> Dict:
        """Analyze experience scaling and leveling pace."""
        # This is a placeholder - we need to implement XP table analysis
        # For now, we'll generate a basic analysis structure
        
        levels = list(range(1, 51))  # Levels 1-50
        
        # Placeholder XP curve (exponential growth)
        xp_required = []
        total_xp = 0
        base_xp = 100
        
        for level in levels:
            xp_for_level = base_xp * (1.1 ** level)  # 10% increase per level
            xp_required.append(xp_for_level)
            total_xp += xp_for_level
        
        # Calculate estimated time per level (assuming constant XP gain rate)
        xp_per_hour = 500  # Placeholder - this should come from game data
        hours_per_level = [xp / xp_per_hour for xp in xp_required]
        
        # Identify problem areas
        problem_levels = []
        for i, hours in enumerate(hours_per_level):
            if hours > target_hours_per_level * 1.5:  # 50% over target
                problem_levels.append({
                    'level': levels[i],
                    'hours_required': hours,
                    'target_hours': target_hours_per_level,
                    'excess_factor': hours / target_hours_per_level
                })
        
        return {
            'levels': levels,
            'xp_required': xp_required,
            'hours_per_level': hours_per_level,
            'target_hours_per_level': target_hours_per_level,
            'problem_levels': problem_levels,
            'total_hours_to_max': sum(hours_per_level)
        }
    
    def generate_progression_curves(self, jobs: List[str] = None, max_level: int = 50) -> Dict:
        """Generate comprehensive progression curve data for visualization."""
        try:
            if jobs is None or len(jobs) == 0:
                jobs_data = self.get_jobs_data()
                jobs = list(jobs_data.keys())[:5]  # Limit to first 5 jobs for performance
            
            # Filter out any empty or invalid job names
            jobs = [job for job in jobs if job and isinstance(job, str)]
            
            if not jobs:
                print("No valid jobs found for progression curves")
                return {}
            
            levels = list(range(1, max_level + 1))
            curves = {}
            
            for job in jobs:
                try:
                    job_curve = {
                        'levels': levels,
                        'attack_power': [],
                        'magic_power': [],
                        'defense': [],
                        'survivability': [],
                        'hp': [],
                        'mp': []
                    }
                    
                    for level in levels:
                        power_data = self.calculate_character_power(level, job)
                        job_curve['attack_power'].append(power_data['attack_power'])
                        job_curve['magic_power'].append(power_data['magic_power'])
                        job_curve['defense'].append(power_data['defense'])
                        job_curve['survivability'].append(power_data['survivability'])
                        job_curve['hp'].append(power_data['hp'])
                        job_curve['mp'].append(power_data['mp'])
                    
                    curves[job] = job_curve
                    print(f"Generated progression curve for {job}")
                    
                except Exception as e:
                    print(f"Error generating curve for job {job}: {e}")
                    continue
            
            return curves
        except Exception as e:
            print(f"Error in generate_progression_curves: {e}")
            return {}
    
    def get_balance_summary(self) -> Dict:
        """Get a high-level balance summary for the dashboard."""
        jobs_data = self.get_jobs_data()
        skills_data = self.get_skills_data()
        items_data = self.get_items_data()
        
        # Generate sample character at level 25 for analysis
        sample_level = 25
        sample_characters = {}
        
        for job in list(jobs_data.keys())[:5]:  # Sample first 5 jobs
            sample_characters[job] = self.calculate_character_power(sample_level, job)
        
        # Analyze equipment distribution
        equipment_analysis = self.analyze_equipment_progression()
        weapon_count = len([item for item in equipment_analysis if item['type'] == 'weapon'])
        armor_count = len([item for item in equipment_analysis if item['type'] == 'armor'])
        
        # Basic skill analysis
        skill_count = len(skills_data)
        
        return {
            'total_jobs': len(jobs_data),
            'total_skills': skill_count,
            'total_weapons': weapon_count,
            'total_armor': armor_count,
            'sample_level': sample_level,
            'sample_characters': sample_characters,
            'equipment_tiers': {
                'basic': len([item for item in equipment_analysis if item['max_requirement'] <= 8]),
                'intermediate': len([item for item in equipment_analysis if 9 <= item['max_requirement'] <= 15]),
                'advanced': len([item for item in equipment_analysis if item['max_requirement'] >= 16])
            }
        } 

    def calculate_monster_effective_power(self, monster_id: str) -> Optional[Dict[str, Any]]:
        """
        Calculates effective power for a given monster.
        For now, it primarily extracts base stats. Can be expanded for abilities/buffs.
        """
        monsters_data = self.get_monsters_data()
        monster_data = monsters_data.get(monster_id)

        if not monster_data or not isinstance(monster_data, dict):
            print(f"Warning: Monster ID '{monster_id}' not found or invalid in monster_definitions.lua")
            return None

        stats = monster_data.get('stats', {})
        if not isinstance(stats, dict):
            print(f"Warning: Stats for monster ID '{monster_id}' are not in the expected format.")
            return None
            
        # Base effective power is current stats. This can be expanded.
        # e.g., consider resistances/immunities to calculate effective HP against certain damage types
        effective_power = {
            "id": monster_id,
            "name": monster_data.get("name", "Unknown Monster"),
            "level": stats.get("level", 0),
            "hp": stats.get("hp", 0),
            "attack": stats.get("attack", 0),
            "defense": stats.get("defense", 0),
            "speed": stats.get("speed", 0),
            "magic_attack": stats.get("magicAttack", 0), # Corrected key based on Lua
            "magic_defense": stats.get("magicDefense", stats.get("defense", 0)), # Assuming magic_defense might use defense if not present
            "abilities": monster_data.get("abilities", []),
            "resistances": monster_data.get("resistances", {}),
            "immunities": monster_data.get("immunities", []),
            # Try to get xp_reward from stats, fallback to xp, then 0
            "xp_reward": stats.get("xpReward", stats.get("xp", 0)), 
            # Try to get loot from monster_data, then from stats, then empty list
            "loot_drops": monster_data.get("loot", stats.get("loot", [])) 
        }
        return effective_power

    def calculate_monster_weighted_ability_damage_and_effects(self, monster_id: str, target_player_stats: Dict) -> Dict[str, Any]:
        """
        Calculates the weighted average damage of a monster based on its abilities
        and lists potential status effects.
        Follows logic from monsterAttackSystem.lua for damage calculation.
        """
        monster_definition = self.get_monsters_data().get(monster_id)
        all_monster_abilities_defs = self.get_monster_abilities_data()

        if not monster_definition or not isinstance(monster_definition, dict):
            print(f"Warning: Monster definition for '{monster_id}' not found or invalid.")
            return {"average_damage": 1.0, "possible_effects": []} # Default low damage

        monster_stats = monster_definition.get('stats', {})
        if not isinstance(monster_stats, dict):
            print(f"Warning: Stats for monster '{monster_id}' are invalid.")
            return {"average_damage": 1.0, "possible_effects": []}

        monster_defined_abilities = monster_definition.get('abilities')
        if not monster_defined_abilities or not isinstance(monster_defined_abilities, (list, dict)): # Lua arrays can be lists or dicts
            # Fallback to a basic physical attack if no abilities defined for some reason
            # This is a safety net, ideally monsters always have abilities if they attack
            base_attack = monster_stats.get('attack', 10)
            player_defense = target_player_stats.get('defense', 5)
            defense_reduction = math.floor(player_defense / 2)
            damage = max(1, math.floor(base_attack * (100 / 100) - defense_reduction)) # Assume 100 basePower for basic attack
            return {"average_damage": float(damage), "possible_effects": ["basic_attack_fallback"]}

        total_weighted_damage = 0.0
        all_possible_effects = set()
        
        # Handle if monster_defined_abilities is a dict (Lua table) or list
        actual_abilities_to_iterate = []
        if isinstance(monster_defined_abilities, dict):
            actual_abilities_to_iterate = list(monster_defined_abilities.values())
        elif isinstance(monster_defined_abilities, list):
            actual_abilities_to_iterate = monster_defined_abilities

        for ability_entry in actual_abilities_to_iterate:
            if not isinstance(ability_entry, dict) or 'id' not in ability_entry:
                print(f"Warning: Invalid ability entry for {monster_id}: {ability_entry}")
                continue

            ability_id = ability_entry['id']
            chance_to_use = float(ability_entry.get('chanceToUse', 0.0))
            if chance_to_use == 0.0:
                continue

            ability_def = all_monster_abilities_defs.get(ability_id)
            if not ability_def or not isinstance(ability_def, dict):
                print(f"Warning: Ability definition for '{ability_id}' not found for monster '{monster_id}'. Skipping.")
                continue

            ability_type = ability_def.get('type')
            ability_base_power = float(ability_def.get('basePower', 0))

            # Determine monster's attack power for this ability type
            monster_attack_for_ability = 0.0 # Ensure float
            if ability_type == "physical":
                monster_attack_for_ability = float(monster_stats.get('attack', 10))
            elif ability_type == "magical":
                monster_attack_for_ability = float(monster_stats.get('magicAttack', 8))
            else: # Support or other types that don't do damage directly this way
                if ability_def.get('effect'):
                     all_possible_effects.add(ability_def['effect'].get('type', 'unknown_effect'))
                continue # Skip damage calculation for non-damaging types

            # New damage calculation logic to match updated monsterAttackSystem.lua
            raw_offense = monster_attack_for_ability * 2
            player_raw_defense = float(target_player_stats.get('defense', 5)) # Ensure float

            effective_defense = 0.0
            if ability_type == "physical":
                effective_defense = math.floor(player_raw_defense / 2)
            elif ability_type == "magical":
                effective_defense = math.floor(player_raw_defense / 3)
            else: # Fallback for other damage-dealing types if any
                effective_defense = math.floor(player_raw_defense / 2)
            
            # Damage = (AbilityBasePower / 100) * (ScaledAttackerStat - EffectivePlayerDefense)
            damage = math.floor((ability_base_power / 100.0) * (raw_offense - effective_defense))
            damage = max(1.0, float(damage)) # Ensure min damage of 1.0 and float type

            # Resistances and status effects are ignored for this simplified simulation for now

            total_weighted_damage += damage * chance_to_use
            
            # Collect effects
            if ability_def.get('effect') and isinstance(ability_def['effect'], dict) and 'type' in ability_def['effect']:
                all_possible_effects.add(ability_def['effect']['type'])
            # Handle if 'effects' is a list of effect tables
            if ability_def.get('effects') and isinstance(ability_def['effects'], list):
                for eff_obj in ability_def['effects']:
                    if isinstance(eff_obj, dict) and 'type' in eff_obj:
                        all_possible_effects.add(eff_obj['type'])


        return {
            "average_damage": total_weighted_damage if total_weighted_damage > 0 else 1.0, # Ensure min 1 if all abilities were non-damaging
            "possible_effects": sorted(list(all_possible_effects))
        }

    def analyze_encounter_balance(self, player_job_id: str, player_level: int, monster_id: str, equipment_tier: str = "basic") -> Optional[Dict[str, Any]]:
        """
        Analyzes the balance of an encounter between a player and a monster.
        """
        player_power = self.calculate_character_power(player_level, player_job_id, equipment_tier)
        monster_power_stats = self.calculate_monster_effective_power(monster_id) # Contains base stats

        if not player_power or not monster_power_stats:
            print("Error: Could not retrieve player or base monster power for encounter analysis.")
            return None

        # New: Calculate monster's weighted damage and effects
        monster_damage_and_effects = self.calculate_monster_weighted_ability_damage_and_effects(monster_id, player_power)
        monster_dps = monster_damage_and_effects["average_damage"]
        monster_possible_effects = monster_damage_and_effects["possible_effects"]

        # Player DPS (simplified for now, needs similar ability-based overhaul later)
        player_effective_attack = player_power.get('attack_power', player_power.get('magic_power', 0))
        monster_effective_defense = max(0, monster_power_stats.get('defense', 0))
        player_damage_per_hit = max(1, player_effective_attack - monster_effective_defense)
        player_dps = player_damage_per_hit # Assuming 1 hit per round for player too

        ttk = self.calculate_ttk(player_dps, monster_power_stats.get('hp', 1))
        survivability_rounds = self.calculate_player_survivability(player_power.get('hp', 1), monster_dps)

        analysis_result = {
            "player_job": player_job_id,
            "player_level": player_level,
            "monster_id": monster_id,
            "monster_name": monster_power_stats.get("name"),
            "monster_level": monster_power_stats.get("level"),
            "player_dps_estimate": player_dps,
            "monster_dps_estimate": monster_dps, # Using new weighted DPS
            "monster_possible_effects": monster_possible_effects, # New field
            "ttk_rounds": ttk,
            "player_survivability_rounds": survivability_rounds,
            "xp_reward": monster_power_stats.get("xp_reward", 0),
            "loot_drops": monster_power_stats.get("loot_drops", [])
        }
        
        if ttk > 0 and ttk != float('inf'):
            analysis_result["xp_per_ttk"] = monster_power_stats.get("xp_reward", 0) / ttk
        else:
            analysis_result["xp_per_ttk"] = 0

        return analysis_result

    def calculate_ttk(self, player_dps: float, monster_hp: float) -> float:
        """
        Calculates Time-To-Kill (TTK) in rounds/seconds.
        Assumes player_dps is effective damage per round/second.
        """
        if player_dps <= 0:
            return float('inf') # Avoid division by zero; effectively infinite time
        return monster_hp / player_dps

    def calculate_player_survivability(self, player_hp: float, monster_dps: float) -> float:
        """
        Calculates how many rounds/seconds a player can survive.
        Assumes monster_dps is effective damage taken by player per round/second.
        """
        if monster_dps <= 0:
            return float('inf') # Player takes no damage
        return player_hp / monster_dps

    def analyze_monster_power_progression(self) -> List[Dict[str, Any]]:
        """
        Analyzes the power progression of all monsters.
        Returns a list of dictionaries, each containing key stats for a monster.
        """
        monsters_data = self.get_monsters_data()
        progression_data = []

        if not monsters_data or not isinstance(monsters_data, dict):
            print("Error: Monster data is not available or not in dict format.")
            return []

        for monster_id in monsters_data.keys():
            effective_power = self.calculate_monster_effective_power(monster_id)
            if effective_power:
                progression_data.append({
                    "id": monster_id,
                    "name": effective_power["name"],
                    "level": effective_power["level"],
                    "hp": effective_power["hp"],
                    "attack": effective_power["attack"],
                    "defense": effective_power["defense"],
                    "magic_attack": effective_power["magic_attack"],
                    "speed": effective_power["speed"]
                })
        
        # Sort by level for easier visualization
        progression_data.sort(key=lambda m: m.get("level", 0))
        return progression_data

    def analyze_monster_difficulty_curve(self, reference_job_id: str = "Fighter", reference_equipment_tier: str = "basic") -> List[Dict[str, Any]]:
        """
        Analyzes the perceived difficulty of monsters against a standard player of the same level.
        Difficulty is measured by how much damage a monster can output relative to a standard player's HP.
        """
        monsters_data = self.get_monsters_data()
        difficulty_curve_data = []

        if not monsters_data or not isinstance(monsters_data, dict):
            print("Error: Monster data is not available or not in dict format for difficulty curve.")
            return []

        sorted_monster_ids = sorted(monsters_data.keys(), key=lambda mid: monsters_data[mid].get('stats', {}).get('level', 0))

        for monster_id in sorted_monster_ids:
            monster_base_stats = self.calculate_monster_effective_power(monster_id)
            if not monster_base_stats or not isinstance(monster_base_stats, dict):
                continue

            monster_level = monster_base_stats.get("level")
            if monster_level is None or monster_level <= 0: # Skip monsters with no/invalid level
                continue

            # Assume a standard player of the same level as the monster
            standard_player_stats = self.calculate_character_power(monster_level, reference_job_id, reference_equipment_tier)
            if not standard_player_stats or not standard_player_stats.get('hp', 0) > 0:
                print(f"Warning: Could not get valid standard player stats for level {monster_level}. Skipping monster {monster_id} for difficulty curve.")
                continue

            # Calculate monster's weighted damage against this standard player
            monster_damage_info = self.calculate_monster_weighted_ability_damage_and_effects(monster_id, standard_player_stats)
            monster_avg_damage_per_round = monster_damage_info.get("average_damage", 1.0)

            # Difficulty score: monster's average damage as a percentage of player's HP
            # Higher score means monster takes a larger chunk of player HP per round, thus more dangerous.
            difficulty_score = (monster_avg_damage_per_round / standard_player_stats['hp']) * 100 if standard_player_stats['hp'] > 0 else float('inf')
            # Alternative: rounds_to_defeat_player = standard_player_stats['hp'] / monster_avg_damage_per_round (lower is harder)
            # difficulty_score = 1 / rounds_to_defeat_player if rounds_to_defeat_player > 0 else float('inf')

            difficulty_curve_data.append({
                "monster_id": monster_id,
                "monster_name": monster_base_stats.get("name", monster_id),
                "monster_level": monster_level,
                "difficulty_score": round(difficulty_score, 2),
                "monster_avg_dpr": round(monster_avg_damage_per_round, 2),
                "ref_player_hp_at_level": round(standard_player_stats['hp'], 2),
                "ref_player_job": reference_job_id,
                "ref_player_equip_tier": reference_equipment_tier
            })
        
        return difficulty_curve_data 