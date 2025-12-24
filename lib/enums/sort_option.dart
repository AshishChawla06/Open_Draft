enum SortOption { title, author, dateCreated, dateUpdated }

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.title:
        return 'Title (A-Z)';
      case SortOption.author:
        return 'Author (A-Z)';
      case SortOption.dateCreated:
        return 'Date Created';
      case SortOption.dateUpdated:
        return 'Date Updated';
    }
  }
}
