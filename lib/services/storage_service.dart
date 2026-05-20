import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Uploads an [XFile] picked via image_picker to the given Storage folder.
  /// Cross-platform: uses bytes + content type, which works on mobile, desktop,
  /// and web (where dart:io File is unavailable).
  Future<String> uploadImage(XFile file, String folder) async {
    final ext = _extOf(file.name);
    final ref = _storage.ref('$folder/${_uuid.v4()}$ext');
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: file.mimeType ?? _guessMimeType(ext),
    );
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _extOf(String name) {
    final i = name.lastIndexOf('.');
    return i == -1 ? '' : name.substring(i);
  }

  String _guessMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
