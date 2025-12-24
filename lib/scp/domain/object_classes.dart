import 'package:flutter/material.dart';

/// SCP Object Classes with their properties
enum SCPObjectClass {
  safe,
  euclid,
  keter,
  thaumiel,
  neutralized,
  explained,
  apollyon,
  decommissioned;

  String get displayName {
    switch (this) {
      case SCPObjectClass.safe:
        return 'Safe';
      case SCPObjectClass.euclid:
        return 'Euclid';
      case SCPObjectClass.keter:
        return 'Keter';
      case SCPObjectClass.thaumiel:
        return 'Thaumiel';
      case SCPObjectClass.neutralized:
        return 'Neutralized';
      case SCPObjectClass.explained:
        return 'Explained';
      case SCPObjectClass.apollyon:
        return 'Apollyon';
      case SCPObjectClass.decommissioned:
        return 'Decommissioned';
    }
  }

  Color get color {
    switch (this) {
      case SCPObjectClass.safe:
        return const Color(0xFF00AA00);
      case SCPObjectClass.euclid:
        return const Color(0xFFFFAA00);
      case SCPObjectClass.keter:
        return const Color(0xFFFF0000);
      case SCPObjectClass.thaumiel:
        return const Color(0xFF000000);
      case SCPObjectClass.neutralized:
        return const Color(0xFF0088FF);
      case SCPObjectClass.explained:
        return const Color(0xFF888888);
      case SCPObjectClass.apollyon:
        return const Color(0xFF8B0000);
      case SCPObjectClass.decommissioned:
        return const Color(0xFF666666);
    }
  }

  String get description {
    switch (this) {
      case SCPObjectClass.safe:
        return 'Easily and safely contained';
      case SCPObjectClass.euclid:
        return 'Unpredictable or not fully understood';
      case SCPObjectClass.keter:
        return 'Extremely difficult to contain';
      case SCPObjectClass.thaumiel:
        return 'Top secret, used to contain other SCPs';
      case SCPObjectClass.neutralized:
        return 'No longer anomalous';
      case SCPObjectClass.explained:
        return 'Fully understood and explainable';
      case SCPObjectClass.apollyon:
        return 'Cannot be contained';
      case SCPObjectClass.decommissioned:
        return 'Destroyed or no longer in Foundation custody';
    }
  }

  static SCPObjectClass fromString(String value) {
    return SCPObjectClass.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SCPObjectClass.safe,
    );
  }
}

/// SCP Hazard Types
enum SCPHazardType {
  biological,
  cognitohazard,
  memetic,
  infohazard,
  radiation,
  temporal,
  spatial,
  reality,
  antimemetic;

  String get displayName {
    switch (this) {
      case SCPHazardType.biological:
        return 'Biological';
      case SCPHazardType.cognitohazard:
        return 'Cognitohazard';
      case SCPHazardType.memetic:
        return 'Memetic';
      case SCPHazardType.infohazard:
        return 'Infohazard';
      case SCPHazardType.radiation:
        return 'Radiation';
      case SCPHazardType.temporal:
        return 'Temporal';
      case SCPHazardType.spatial:
        return 'Spatial';
      case SCPHazardType.reality:
        return 'Reality Bending';
      case SCPHazardType.antimemetic:
        return 'Antimemetic';
    }
  }

  IconData get icon {
    switch (this) {
      case SCPHazardType.biological:
        return Icons.biotech;
      case SCPHazardType.cognitohazard:
        return Icons.psychology;
      case SCPHazardType.memetic:
        return Icons.share;
      case SCPHazardType.infohazard:
        return Icons.info;
      case SCPHazardType.radiation:
        return Icons.warning_amber;
      case SCPHazardType.temporal:
        return Icons.access_time;
      case SCPHazardType.spatial:
        return Icons.public;
      case SCPHazardType.reality:
        return Icons.auto_fix_high;
      case SCPHazardType.antimemetic:
        return Icons.visibility_off;
    }
  }

  Color get color {
    return const Color(0xFFFF4444);
  }
}
