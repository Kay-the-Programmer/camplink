import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

class StorageService {
  /// Uploads an [XFile] to the backend and returns the host-relative path it
  /// was stored at (e.g. `/api/files/uuid.jpg`). Storing the relative path
  /// keeps image references portable across environments; resolve it to a full
  /// URL with [ApiClient.fileUrl] when displaying.
  Future<String> uploadImage(XFile file, String folder) async {
    final result = await ApiClient.uploadFile(file.path);
    return result['path'] as String;
  }

  /// Uploads several images in sequence, returning their relative paths in the
  /// same order. Stops and rethrows on the first failure.
  Future<List<String>> uploadImages(List<XFile> files, String folder) async {
    final paths = <String>[];
    for (final f in files) {
      paths.add(await uploadImage(f, folder));
    }
    return paths;
  }
}
