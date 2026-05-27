import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

class StorageService {
  /// Uploads an [XFile] to the backend and returns the full image URL.
  Future<String> uploadImage(XFile file, String folder) async {
    final result = await ApiClient.uploadFile(file.path);
    final path = result['path'] as String;
    return ApiClient.fileUrl(path);
  }
}
