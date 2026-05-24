import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

Future<String?> decodeQrFromFile(String filePath) async {
  try {
    final bytes = await File(filePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final source = RGBLuminanceSource(
      image.width,
      image.height,
      image
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.abgr)
          .buffer
          .asInt32List(),
    );
    final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));

    final reader = QRCodeReader();
    final result = reader.decode(bitmap);
    return result.text;
  } catch (_) {
    return null;
  }
}
