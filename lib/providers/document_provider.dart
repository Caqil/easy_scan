import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/document.dart';
import '../utils/constants.dart';

class DocumentNotifier extends StateNotifier<List<Document>> {
  final Box<Document> _documentsBox;

  DocumentNotifier(this._documentsBox) : super([]) {
    _loadDocuments();
  }

  void _loadDocuments() {
    state = _documentsBox.values.toList();
  }

  Future<void> addDocument(Document document) async {
    await _documentsBox.put(document.id, document);
    _loadDocuments();
  }

  Future<void> updateDocument(Document document) async {
    document.modifiedAt = DateTime.now();
    await _documentsBox.put(document.id, document);
    _loadDocuments();
  }

  Future<void> deleteDocument(String id) async {
    await _documentsBox.delete(id);
    _loadDocuments();
  }

  List<Document> getDocumentsByFolder(String? folderId) {
    return state.where((doc) => doc.folderId == folderId).toList();
  }

  List<Document> getFavorites() {
    return state.where((doc) => doc.isFavorite).toList();
  }

  List<Document> searchDocuments(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where((doc) =>
            doc.name.toLowerCase().contains(lowercaseQuery) ||
            doc.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }
}

final documentBoxProvider = Provider<Box<Document>>((ref) {
  return Hive.box<Document>(AppConstants.documentsBoxName);
});

final documentsProvider =
    StateNotifierProvider<DocumentNotifier, List<Document>>((ref) {
  final box = ref.watch(documentBoxProvider);
  return DocumentNotifier(box);
});

// Recent documents provider
final recentDocumentsProvider = Provider<List<Document>>((ref) {
  final documents = ref.watch(documentsProvider);
  final sortedDocs = [...documents];
  sortedDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  return sortedDocs.take(5).toList();
});

// Favorites documents provider
final favoriteDocumentsProvider = Provider<List<Document>>((ref) {
  final documents = ref.watch(documentsProvider);
  return documents.where((doc) => doc.isFavorite).toList();
});

// Documents in folder provider
final documentsInFolderProvider =
    Provider.family<List<Document>, String?>((ref, folderId) {
  final documents = ref.watch(documentsProvider);
  return documents.where((doc) => doc.folderId == folderId).toList();
});
