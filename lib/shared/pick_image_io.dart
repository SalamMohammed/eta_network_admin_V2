import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class PickedImage {
  final Uint8List bytes;
  final String? contentType;
  PickedImage(this.bytes, this.contentType);
}

Future<PickedImage?> pickImage() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    withReadStream: true,
  );
  final f = res?.files.first;
  Uint8List? b = f?.bytes;
  if ((b == null || b.isEmpty) && f?.readStream != null) {
    final chunks = <int>[];
    await for (final chunk in f!.readStream!) {
      chunks.addAll(chunk);
    }
    b = Uint8List.fromList(chunks);
  }
  if (b == null || b.isEmpty) return null;
  String? ct;
  if (f != null) {
    final name = f.name.toLowerCase();
    if (name.endsWith('.png')) {
      ct = 'image/png';
    } else if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      ct = 'image/jpeg';
    } else if (name.endsWith('.gif')) {
      ct = 'image/gif';
    } else {
      ct = 'application/octet-stream';
    }
  }
  return PickedImage(b, ct);
}
