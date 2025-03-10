import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/folder.dart';
import '../utils/constants.dart';

class FolderNotifier extends StateNotifier<List<Folder>> {
  final Box<Folder> _foldersBox;

  FolderNotifier(this._foldersBox) : super([]) {
    _loadFolders();
  }

  void _loadFolders() {
    state = _foldersBox.values.toList();
  }

  Future<void> addFolder(Folder folder) async {
    await _foldersBox.put(folder.id, folder);
    _loadFolders();
  }

  Future<void> updateFolder(Folder folder) async {
    await _foldersBox.put(folder.id, folder);
    _loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
    _loadFolders();
  }

  List<Folder> getSubfolders(String? parentId) {
    return state.where((folder) => folder.parentId == parentId).toList();
  }

  Folder? getFolder(String id) {
    try {
      return state.firstWhere((folder) => folder.id == id);
    } catch (e) {
      return null;
    }
  }
}

final folderBoxProvider = Provider<Box<Folder>>((ref) {
  return Hive.box<Folder>(AppConstants.foldersBoxName);
});

final foldersProvider =
    StateNotifierProvider<FolderNotifier, List<Folder>>((ref) {
  final box = ref.watch(folderBoxProvider);
  return FolderNotifier(box);
});

// Root folders provider
final rootFoldersProvider = Provider<List<Folder>>((ref) {
  final folders = ref.watch(foldersProvider);
  return folders.where((folder) => folder.parentId == null).toList();
});

// Subfolders provider
final subFoldersProvider =
    Provider.family<List<Folder>, String?>((ref, parentId) {
  final folders = ref.watch(foldersProvider);
  return folders.where((folder) => folder.parentId == parentId).toList();
});
