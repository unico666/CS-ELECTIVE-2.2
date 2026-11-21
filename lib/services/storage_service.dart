import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'product-images';

  Future<String> uploadProductImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final dot = file.name.lastIndexOf('.');
    final extension = dot == -1 ? 'jpg' : file.name.substring(dot + 1).toLowerCase();
    final path = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$extension'),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
