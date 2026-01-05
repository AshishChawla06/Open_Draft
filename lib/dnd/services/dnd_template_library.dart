class AdventureTemplate {
  final String id;
  final String name;
  final String description;
  final String category; // 'One-Shot', 'Mystery', 'Dungeon Crawl', 'Campaign'
  final String templateContent; // JSON template with placeholders
  final List<String> variables; // {{var_name}} placeholders

  const AdventureTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.templateContent,
    required this.variables,
  });
}

class DnDTemplateLibrary {
  static const List<AdventureTemplate> builtInTemplates = [
    AdventureTemplate(
      id: 'oneshot_goblin_raid',
      name: 'Goblin Raid',
      description: 'Classic one-shot: goblins attack a village',
      category: 'One-Shot',
      templateContent: '''
# {{adventure_name}}

## Overview
A band of goblins has been raiding the outskirts of {{village_name}}. The party is hired by {{quest_giver}} to eliminate the threat.

## Act 1: The Tavern
The adventure begins at {{tavern_name}}. {{quest_giver}}, a worried {{quest_giver_role}}, approaches the party with a plea for help.

**Quest Giver Personality:**
- Trait: {{trait_1}}
- Ideal: {{ideal_1}}

## Act 2: The Goblin Camp
The party tracks the goblins to a cave {{distance}} from the village.

**Encounter: Goblin Ambush**
- 4 Goblins (CR 1/4 each)
- Environment: Forest
- Tactics: Hit and run, use cover

## Act 3: Confrontation
Inside the cave, the party faces the goblin chieftain.

**Encounter: Boss Fight**
- 1 Goblin Boss (CR 1)
- 2 Goblin minions (CR 1/4)
- Treasure: {{treasure}}

## Conclusion
Upon defeating the goblins, the party returns to {{village_name}} as heroes.

**Reward:** {{reward_gold}} gold pieces and the gratitude of the villagers.
''',
      variables: [
        'adventure_name',
        'village_name',
        'quest_giver',
        'quest_giver_role',
        'tavern_name',
        'trait_1',
        'ideal_1',
        'distance',
        'treasure',
        'reward_gold',
      ],
    ),

    AdventureTemplate(
      id: 'mystery_murder',
      name: 'Whodunit Mystery',
      description: 'Classic murder mystery investigation',
      category: 'Mystery',
      templateContent: '''
# {{adventure_name}}

## The Crime
{{victim_name}}, a prominent {{victim_role}}, has been found dead in {{location}}. The local authorities have hired the party to solve the case.

## Suspects

### Suspect 1: {{suspect_1_name}}
- Role: {{suspect_1_role}}
- Motive: {{suspect_1_motive}}
- Alibi: {{suspect_1_alibi}}
- Secret: {{suspect_1_secret}}

### Suspect 2: {{suspect_2_name}}
- Role: {{suspect_2_role}}
- Motive: {{suspect_2_motive}}
- Alibi: {{suspect_2_alibi}}
- Secret: {{suspect_2_secret}}

### Suspect 3: {{suspect_3_name}}
- Role: {{suspect_3_role}}
- Motive: {{suspect_3_motive}}
- Alibi: {{suspect_3_alibi}}
- Secret: {{suspect_3_secret}}

## Clues
1. {{clue_1}}
2. {{clue_2}}
3. {{clue_3}}

## The Truth
**Killer:** {{killer_name}}
**Method:** {{murder_method}}
**Why:** {{true_motive}}

## Resolution
The party must gather evidence and confront the killer. A DC {{investigation_dc}} Investigation check reveals the final clue.
''',
      variables: [
        'adventure_name',
        'victim_name',
        'victim_role',
        'location',
        'suspect_1_name',
        'suspect_1_role',
        'suspect_1_motive',
        'suspect_1_alibi',
        'suspect_1_secret',
        'suspect_2_name',
        'suspect_2_role',
        'suspect_2_motive',
        'suspect_2_alibi',
        'suspect_2_secret',
        'suspect_3_name',
        'suspect_3_role',
        'suspect_3_motive',
        'suspect_3_alibi',
        'suspect_3_secret',
        'clue_1',
        'clue_2',
        'clue_3',
        'killer_name',
        'murder_method',
        'true_motive',
        'investigation_dc',
      ],
    ),

    AdventureTemplate(
      id: 'dungeon_crawl',
      name: 'Classic Dungeon Crawl',
      description: 'Room-by-room dungeon exploration',
      category: 'Dungeon Crawl',
      templateContent: '''
# {{dungeon_name}}

## Background
{{dungeon_name}} was once {{dungeon_history}}. Now it serves as a lair for {{main_threat}}.

## Dungeon Map
Total Rooms: {{room_count}}

### Room 1: Entrance Hall
**Description:** {{room_1_desc}}
**Encounter:** {{room_1_encounter}}
**Treasure:** {{room_1_treasure}}
**Secret:** {{room_1_secret}}

### Room 2: {{room_2_name}}
**Description:** {{room_2_desc}}
**Encounter:** {{room_2_encounter}}
**Treasure:** {{room_2_treasure}}
**Trap:** {{room_2_trap}}

### Room 3: {{room_3_name}}
**Description:** {{room_3_desc}}
**Puzzle:** {{room_3_puzzle}}
**Reward:** {{room_3_reward}}

### Boss Room: {{boss_room_name}}
**Description:** {{boss_desc}}
**Encounter:** {{boss_name}} (CR {{boss_cr}})
**Tactics:** {{boss_tactics}}
**Treasure:** {{boss_treasure}}

## GM Notes
- {{gm_note_1}}
- {{gm_note_2}}
''',
      variables: [
        'dungeon_name',
        'dungeon_history',
        'main_threat',
        'room_count',
        'room_1_desc',
        'room_1_encounter',
        'room_1_treasure',
        'room_1_secret',
        'room_2_name',
        'room_2_desc',
        'room_2_encounter',
        'room_2_treasure',
        'room_2_trap',
        'room_3_name',
        'room_3_desc',
        'room_3_puzzle',
        'room_3_reward',
        'boss_room_name',
        'boss_desc',
        'boss_name',
        'boss_cr',
        'boss_tactics',
        'boss_treasure',
        'gm_note_1',
        'gm_note_2',
      ],
    ),
  ];

  /// Apply template with variable replacements
  static String applyTemplate(
    AdventureTemplate template,
    Map<String, String> variables,
  ) {
    String content = template.templateContent;

    for (final entry in variables.entries) {
      content = content.replaceAll('{{${entry.key}}}', entry.value);
    }

    return content;
  }

  /// Get templates by category
  static List<AdventureTemplate> getTemplatesByCategory(String category) {
    return builtInTemplates.where((t) => t.category == category).toList();
  }

  /// Get all categories
  static List<String> getCategories() {
    return builtInTemplates.map((t) => t.category).toSet().toList();
  }
}
