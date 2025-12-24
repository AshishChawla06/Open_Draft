import 'package:flutter_test/flutter_test.dart';
import 'package:opendraft/models/document_type.dart';
import 'package:opendraft/models/scp_metadata.dart';
import 'package:opendraft/models/scp_section.dart';
import 'package:opendraft/models/redaction.dart';
import 'package:opendraft/models/book.dart';
import 'package:opendraft/models/chapter.dart';

void main() {
  group('SCP Data Models Tests', () {
    test('DocumentType enum works correctly', () {
      expect(DocumentType.novel.displayName, 'Novel');
      expect(DocumentType.scp.displayName, 'SCP Article');
      expect(DocumentType.fromString('scp'), DocumentType.scp);
      expect(DocumentType.fromString('novel'), DocumentType.novel);
      expect(DocumentType.fromString('invalid'), DocumentType.novel);
    });

    test('SCPMetadata serialization works', () {
      final metadata = SCPMetadata(
        itemNumber: 'SCP-173',
        objectClass: 'Euclid',
        hazards: ['cognitohazard', 'memetic'],
        clearanceLevel: 3,
        department: 'Containment',
        tags: ['statue', 'hostile'],
        status: 'Published',
        rating: 450,
      );

      // Test toJson
      final json = metadata.toJson();
      expect(json['itemNumber'], 'SCP-173');
      expect(json['objectClass'], 'Euclid');
      expect(json['hazards'], ['cognitohazard', 'memetic']);
      expect(json['clearanceLevel'], 3);

      // Test fromJson
      final restored = SCPMetadata.fromJson(json);
      expect(restored.itemNumber, metadata.itemNumber);
      expect(restored.objectClass, metadata.objectClass);
      expect(restored.hazards, metadata.hazards);
      expect(restored.clearanceLevel, metadata.clearanceLevel);

      // Test JSON string serialization
      final jsonString = metadata.toJsonString();
      final restoredFromString = SCPMetadata.fromJsonString(jsonString);
      expect(restoredFromString.itemNumber, metadata.itemNumber);
    });

    test('Redaction model works correctly', () {
      final redaction = Redaction(
        start: 10,
        end: 20,
        style: 'bar',
        reason: 'Level 4 clearance required',
        clearanceLevel: 4,
        revealed: false,
      );

      // Test toJson
      final json = redaction.toJson();
      expect(json['start'], 10);
      expect(json['end'], 20);
      expect(json['style'], 'bar');
      expect(json['reason'], 'Level 4 clearance required');

      // Test fromJson
      final restored = Redaction.fromJson(json);
      expect(restored.start, redaction.start);
      expect(restored.end, redaction.end);
      expect(restored.style, redaction.style);
      expect(restored.reason, redaction.reason);
    });

    test('SCPSection model works correctly', () {
      final section = SCPSection(
        id: 'section_1',
        type: SCPSectionType.specialContainmentProcedures,
        title: 'Special Containment Procedures',
        content: 'SCP-173 must be kept in a locked container...',
        order: 1,
        required: true,
      );

      expect(section.type.displayName, 'Special Containment Procedures');

      // Test serialization
      final json = section.toJson();
      final restored = SCPSection.fromJson(json);
      expect(restored.id, section.id);
      expect(restored.type, section.type);
      expect(restored.title, section.title);
    });

    test('Book with SCP metadata works correctly', () {
      final scpMetadata = SCPMetadata(
        itemNumber: 'SCP-173',
        objectClass: 'Euclid',
        clearanceLevel: 2,
      );

      final book = Book(
        id: 'book_1',
        title: 'SCP-173',
        author: 'Dr. ████',
        documentType: DocumentType.scp,
        scpMetadata: scpMetadata,
        chapters: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(book.documentType, DocumentType.scp);
      expect(book.scpMetadata?.itemNumber, 'SCP-173');
      expect(book.scpMetadata?.objectClass, 'Euclid');
    });

    test('Chapter with SCP section type and redactions works', () {
      final redactions = [
        Redaction(start: 10, end: 20, style: 'bar'),
        Redaction(start: 50, end: 60, style: 'blur'),
      ];

      final chapter = Chapter(
        id: 'chapter_1',
        title: 'Special Containment Procedures',
        content: 'SCP-173 must be kept in a ████████ container...',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sectionType: SCPSectionType.specialContainmentProcedures,
        redactions: redactions,
      );

      expect(chapter.sectionType, SCPSectionType.specialContainmentProcedures);
      expect(chapter.redactions?.length, 2);
      expect(chapter.redactions?[0].style, 'bar');
      expect(chapter.redactions?[1].style, 'blur');
    });

    test('Book copyWith preserves SCP fields', () {
      final scpMetadata = SCPMetadata(
        itemNumber: 'SCP-173',
        objectClass: 'Euclid',
        clearanceLevel: 2,
      );

      final book = Book(
        id: 'book_1',
        title: 'SCP-173',
        author: 'Dr. ████',
        documentType: DocumentType.scp,
        scpMetadata: scpMetadata,
        chapters: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = book.copyWith(title: 'SCP-173 Updated');
      expect(updated.title, 'SCP-173 Updated');
      expect(updated.documentType, DocumentType.scp);
      expect(updated.scpMetadata?.itemNumber, 'SCP-173');
    });
  });
}
