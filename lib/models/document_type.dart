enum DocumentType {
  novel,
  scp,
  dndAdventure;

  String get displayName {
    switch (this) {
      case DocumentType.novel:
        return 'Novel';
      case DocumentType.scp:
        return 'SCP Article';
      case DocumentType.dndAdventure:
        return 'DnD Adventure';
    }
  }

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.novel,
    );
  }
}
