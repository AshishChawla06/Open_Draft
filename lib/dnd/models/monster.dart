class Monster {
  final String slug;
  final String name;
  final String size;
  final String type;
  final String subtype;
  final String alignment;
  final int armorClass;
  final String? armorDesc;
  final int hitPoints;
  final String hitDice;
  final Map<String, dynamic> speed;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final double challengeRating;
  final List<MonsterAction> actions;
  final String? imgUrl;
  final String source; // 'SRD' or '5e.tools' or 'Custom'

  const Monster({
    required this.slug,
    required this.name,
    required this.size,
    required this.type,
    this.subtype = '',
    this.alignment = '',
    required this.armorClass,
    this.armorDesc,
    required this.hitPoints,
    required this.hitDice,
    required this.speed,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.challengeRating,
    this.actions = const [],
    this.imgUrl,
    this.source = 'SRD',
  });

  factory Monster.fromJson(Map<String, dynamic> json) {
    // Handle Open5e structure
    return Monster(
      slug: json['slug'] ?? '',
      name: json['name'] ?? 'Unknown',
      size: json['size'] ?? '',
      type: json['type'] ?? '',
      subtype: json['subtype'] ?? '',
      alignment: json['alignment'] ?? '',
      armorClass: json['armor_class'] ?? 10,
      armorDesc: json['armor_desc'],
      hitPoints: json['hit_points'] ?? 10,
      hitDice: json['hit_dice'] ?? '',
      speed: json['speed'] is Map
          ? Map<String, dynamic>.from(json['speed'])
          : {},
      strength: json['strength'] ?? 10,
      dexterity: json['dexterity'] ?? 10,
      constitution: json['constitution'] ?? 10,
      intelligence: json['intelligence'] ?? 10,
      wisdom: json['wisdom'] ?? 10,
      charisma: json['charisma'] ?? 10,
      challengeRating: (json['challenge_rating'] is num)
          ? (json['challenge_rating'] as num).toDouble()
          : double.tryParse(json['challenge_rating'].toString()) ?? 0.0,
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => MonsterAction.fromJson(e))
              .toList() ??
          [],
      imgUrl: json['img_main'],
      source: json['document__slug'] ?? 'SRD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'armor_class': armorClass,
      'armor_desc': armorDesc,
      'hit_points': hitPoints,
      'hit_dice': hitDice,
      'speed': speed,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'challenge_rating': challengeRating,
      'actions': actions.map((e) => e.toJson()).toList(),
      'img_main': imgUrl,
      'source': source,
    };
  }
}

class MonsterAction {
  final String name;
  final String desc;
  final int? attackBonus;
  final String? damageDice;
  final String? damageBonus;

  const MonsterAction({
    required this.name,
    required this.desc,
    this.attackBonus,
    this.damageDice,
    this.damageBonus,
  });

  factory MonsterAction.fromJson(Map<String, dynamic> json) {
    return MonsterAction(
      name: json['name'] ?? 'Unknown Action',
      desc: json['desc'] ?? '',
      attackBonus: json['attack_bonus'],
      damageDice: json['damage_dice'],
      damageBonus: json['damage_bonus']
          ?.toString(), // Open5e sometimes sends int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'desc': desc,
      'attack_bonus': attackBonus,
      'damage_dice': damageDice,
      'damage_bonus': damageBonus,
    };
  }
}
