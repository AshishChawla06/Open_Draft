class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid({
    List<String> errors = const [],
    List<String> warnings = const [],
  }) {
    return ValidationResult(isValid: false, errors: errors, warnings: warnings);
  }
}
