import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../models/community.dart';
import 'community_repository.dart';
import 'photo_cleanup.dart' if (dart.library.io) 'photo_cleanup_io.dart';

class PhotoService {
  final _picker = ImagePicker();
  Future<LocalPhoto> _read(XFile file) async {
    if (await file.length() > 15 * 1024 * 1024) {
      await deleteTemporaryCapture(file.path);
      throw const FeatureUnavailable(
        'La imagen supera los 15 MB. Elige una más pequeña.',
      );
    }
    final bytes = await file.readAsBytes();
    await deleteTemporaryCapture(file.path);
    final name = file.name.toLowerCase();
    final mime =
        file.mimeType ??
        (name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
            ? 'image/webp'
            : name.endsWith('.gif')
            ? 'image/gif'
            : name.endsWith('.jpg') || name.endsWith('.jpeg')
            ? 'image/jpeg'
            : null);
    if (!{
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
    }.contains(mime)) {
      throw const FeatureUnavailable(
        'Selecciona una imagen JPG, PNG, WebP o GIF.',
      );
    }
    return LocalPhoto(bytes, file.name, mime!);
  }

  Future<List<LocalPhoto>> pick({required bool camera, int limit = 1}) async {
    try {
      if (camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2400,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        return file == null ? [] : [await _read(file)];
      }
      final files = limit == 1
          ? [
              await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 2400,
                imageQuality: 90,
                requestFullMetadata: false,
              ),
            ].whereType<XFile>().toList()
          : await _picker.pickMultiImage(
              maxWidth: 2400,
              imageQuality: 90,
              requestFullMetadata: false,
            );
      if (files.length > limit) {
        throw FeatureUnavailable('Selecciona como máximo $limit imágenes.');
      }
      return await Future.wait(files.map(_read));
    } on PlatformException {
      throw const FeatureUnavailable(
        'No pudimos abrir la cámara o las fotografías. Revisa los permisos de BioJaveriana en los ajustes del dispositivo.',
      );
    }
  }
}
