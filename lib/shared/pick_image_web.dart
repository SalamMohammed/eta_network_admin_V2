import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedImage {
  final Uint8List bytes;
  final String? contentType;
  PickedImage(this.bytes, this.contentType);
}

Future<PickedImage?> pickImage() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  final completer = Completer<PickedImage?>();
  input.onChange.listen((_) async {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final res = reader.result;
      Uint8List? bytes;
      if (res is ByteBuffer) {
        bytes = Uint8List.view(res);
      } else if (res is List<int>) {
        bytes = Uint8List.fromList(res);
      }
      if (bytes == null || bytes.isEmpty) {
        completer.complete(null);
        return;
      }
      final type = file.type;
      completer.complete(PickedImage(bytes, type.isNotEmpty ? type : null));
    });
    reader.onError.listen((_) => completer.complete(null));
  });
  input.click();
  return completer.future;
}
