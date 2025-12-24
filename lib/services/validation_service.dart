import '../models/book.dart';
import '../models/document_type.dart';
import '../models/validation_result.dart';
import '../scp/domain/object_classes.dart';

class ValidationService {
  static ValidationResult validateBook(Book book) {
    final errors = <String>[];
    final warnings = <String>[];

    // General Validation
    if (book.title.trim().isEmpty) {
      errors.add('Book title cannot be empty.');
    }

    if (book.chapters.isEmpty) {
      warnings.add('Book has no chapters.');
    }

    // SCP Specific Validation
    if (book.documentType == DocumentType.scp) {
      if (book.scpMetadata == null) {
        errors.add('Missing SCP Metadata.');
      } else {
        final metadata = book.scpMetadata!;

        if (metadata.itemNumber == 'SCP-XXXX' || metadata.itemNumber.isEmpty) {
          warnings.add('Item number is set to default (SCP-XXXX) or empty.');
        }

        if (metadata.objectClass.isEmpty || metadata.objectClass == 'Unknown') {
          warnings.add('Object Class is not specified.');
        } else {
          // check against valid enum
          final isValidClass = SCPObjectClass.values.any(
            (e) => e.displayName == metadata.objectClass,
          );
          if (!isValidClass) {
            warnings.add(
              'Object Class "${metadata.objectClass}" is non-standard.',
            );
          }
        }
      }

      // SCPs should have at least one chapter usually "Containment Procedures" or "Description"
      // We already checked chapters.isEmpty generally, but maybe check specific content?
      // For now, keep it simple.
    }

    if (errors.isEmpty && warnings.isEmpty) {
      return ValidationResult.valid();
    }

    return ValidationResult.invalid(errors: errors, warnings: warnings);
  }
}
