import 'package:flutter_test/flutter_test.dart';
import 'package:mindnote/models/note.dart';

void main() {
  group('Note Model Tests', () {
    test('should create empty note', () {
      final note = Note.empty();
      expect(note.title, '');
      expect(note.content, '');
      expect(note.tags, isEmpty);
      expect(note.isEmpty, true);
    });

    test('should create note with values', () {
      final note = Note(
        title: 'Test Note',
        content: 'This is test content',
        tags: ['test', 'flutter'],
      );

      expect(note.title, 'Test Note');
      expect(note.content, 'This is test content');
      expect(note.tags, ['test', 'flutter']);
      expect(note.isEmpty, false);
      expect(note.isFavorite, false);
    });

    test('should convert to map and back', () {
      final original = Note(
        title: 'Map Test',
        content: 'Testing serialization',
        tags: ['serialize', 'test'],
        isFavorite: true,
      );

      final map = original.toMap();
      final restored = Note.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.tags, original.tags);
      expect(restored.isFavorite, original.isFavorite);
    });

    test('should copy with modifications', () {
      final original = Note(
        title: 'Original',
        content: 'Original content',
      );

      final modified = original.copyWith(
        title: 'Modified',
        isFavorite: true,
      );

      expect(modified.id, original.id);
      expect(modified.title, 'Modified');
      expect(modified.content, 'Original content');
      expect(modified.isFavorite, true);
    });
  });

  group('Note Validation Tests', () {
    test('empty note should be detected', () {
      final empty = Note.empty();
      expect(empty.isEmpty, true);
    });

    test('note with only title should not be empty', () {
      final note = Note(title: 'Title Only', content: '');
      expect(note.isEmpty, false);
    });

    test('note with only content should not be empty', () {
      final note = Note(title: '', content: 'Content only');
      expect(note.isEmpty, false);
    });
  });
}
