enum DocumentType {
  novel,
  scp;

  String get displayName {
    switch (this) {
      case DocumentType.novel:
        return 'Novel';
      case DocumentType.scp:
        return 'SCP Article';
    }
  }

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.novel,
    );
  }
}
