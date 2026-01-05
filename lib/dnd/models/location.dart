import 'package:uuid/uuid.dart';
import '../../models/redaction.dart';

class Location {
  final String id;
  final String adventureId;
  final String name;
  final String region;
  final String environment; // e.g., 'Dungeon', 'City', 'Forest'
  final String description;

  // Rooms/Areas
  final List<LocationRoom> rooms;

  // Map support
  final String? mapImageUrl;
  final String mapNotes;

  // Secrets & Clues
  final List<Redaction>? redactions;

  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.adventureId,
    required this.name,
    this.region = '',
    this.environment = '',
    this.description = '',
    this.rooms = const [],
    this.mapImageUrl,
    this.mapNotes = '',
    this.redactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Location copyWith({
    String? name,
    String? region,
    String? environment,
    String? description,
    List<LocationRoom>? rooms,
    String? mapImageUrl,
    String? mapNotes,
    List<Redaction>? redactions,
  }) {
    return Location(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      region: region ?? this.region,
      environment: environment ?? this.environment,
      description: description ?? this.description,
      rooms: rooms ?? this.rooms,
      mapImageUrl: mapImageUrl ?? this.mapImageUrl,
      mapNotes: mapNotes ?? this.mapNotes,
      redactions: redactions ?? this.redactions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adventureId': adventureId,
      'name': name,
      'region': region,
      'environment': environment,
      'description': description,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'mapImageUrl': mapImageUrl,
      'mapNotes': mapNotes,
      'redactions': redactions?.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      adventureId: json['adventureId'] ?? '',
      name: json['name'] ?? 'Unnamed Location',
      region: json['region'] ?? '',
      environment: json['environment'] ?? '',
      description: json['description'] ?? '',
      rooms:
          (json['rooms'] as List?)
              ?.map((r) => LocationRoom.fromJson(r))
              .toList() ??
          [],
      mapImageUrl: json['mapImageUrl'],
      mapNotes: json['mapNotes'] ?? '',
      redactions: (json['redactions'] as List?)
          ?.map((r) => Redaction.fromJson(r))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory Location.empty(String adventureId) {
    return Location(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: 'New Location',
    );
  }
}

class LocationRoom {
  final String id;
  final String name;
  final String description;
  final String secrets; // Hidden clues, triggers
  final List<String> features; // Notable features

  LocationRoom({
    required this.id,
    required this.name,
    this.description = '',
    this.secrets = '',
    this.features = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'secrets': secrets,
      'features': features,
    };
  }

  factory LocationRoom.fromJson(Map<String, dynamic> json) {
    return LocationRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Room',
      description: json['description'] ?? '',
      secrets: json['secrets'] ?? '',
      features: List<String>.from(json['features'] ?? []),
    );
  }

  factory LocationRoom.empty() {
    return LocationRoom(id: const Uuid().v4(), name: 'New Room');
  }
}
