#!/usr/bin/env python3
"""
Monster Database Expansion Script
Fetches monsters from D&D 5e SRD API and converts to app JSON format
Run: python scripts/expand_monsters.py
"""

import requests
import json
import time

API_BASE = "https://www.dnd5eapi.co/api/monsters"
OUTPUT_FILE = "../assets/data/monsters_srd.json"

def fetch_all_monsters():
    """Fetch all monster data from the SRD API"""
    print("Fetching monster list...")
    response = requests.get(API_BASE)
    monster_list = response.json()['results']
    
    monsters = []
    total = len(monster_list)
    
    for i, monster_ref in enumerate(monster_list):
        print(f"Fetching {i+1}/{total}: {monster_ref['name']}")
        
        # Fetch detailed monster data
        detail_url = f"https://www.dnd5eapi.co{monster_ref['url']}"
        detail = requests.get(detail_url).json()
        
        # Convert to our format
        monster = {
            "slug": detail['index'],
            "name": detail['name'],
            "size": detail['size'],
            "type": detail['type'],
            "subtype": detail.get('subtype', ''),
            "alignment": detail['alignment'],
            "armor_class": detail['armor_class'][0]['value'] if detail.get('armor_class') else 10,
            "hit_points": detail['hit_points'],
            "hit_dice": detail['hit_dice'],
            "speed": detail['speed'],
            "str": detail['strength'],
            "dex": detail['dexterity'],
            "con": detail['constitution'],
            "int": detail['intelligence'],
            "wis": detail['wisdom'],
            "cha": detail['charisma'],
            "challenge_rating": detail['challenge_rating'],
            "source": "SRD"
        }
        
        monsters.append(monster)
        time.sleep(0.1)  # Rate limiting
    
    return monsters

def save_monsters(monsters):
    """Save monsters to JSON file"""
    output = {"monsters": monsters}
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"\\n✅ Saved {len(monsters)} monsters to {OUTPUT_FILE}")

if __name__ == "__main__":
    try:
        monsters = fetch_all_monsters()
        save_monsters(monsters)
        print(f"\\n🎲 Database now contains {len(monsters)} SRD monsters!")
    except Exception as e:
        print(f"❌ Error: {e}")
