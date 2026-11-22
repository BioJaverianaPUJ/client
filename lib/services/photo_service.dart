import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';

import '../theme/bio_theme.dart';
import '../models/community.dart';
import 'community_repository.dart';
import 'photo_cleanup.dart' if (dart.library.io) 'photo_cleanup_io.dart';

/// Recorte nativo antes de subir una imagen (uCrop en Android,
/// TOCropViewController en iOS): la persona mueve y ajusta el encuadre.
enum PhotoCrop {
  /// Foto de perfil: cuadrada, con guía circular.
  avatar,

  /// Banner del perfil: panorámico 2:1.
  banner,

  /// Fotos de publicaciones: cuadrada por defecto, con otras proporciones.
  post,
}

class _Ratio implements CropAspectRatioPresetData {
  const _Ratio(this.x, this.y, this.name);
  final int x, y;
  @override
  final String name;
  @override
  (int, int)? get data => (x, y);
}

class PhotoService {
  final _picker = ImagePicker();

  /// Devuelve la ruta recortada, la original si no hay recorte o null si la
  /// persona canceló.
  Future<String?> _crop(String path, PhotoCrop crop) async {
    const title = {
      PhotoCrop.avatar: 'Ajusta tu foto',
      PhotoCrop.banner: 'Ajusta tu banner',
      PhotoCrop.post: 'Ajusta la imagen',
    };
    final fixed = switch (crop) {
      PhotoCrop.avatar => const CropAspectRatio(ratioX: 1, ratioY: 1),
      PhotoCrop.banner => const CropAspectRatio(ratioX: 2, ratioY: 1),
      PhotoCrop.post => null,
    };
    const postRatios = <CropAspectRatioPresetData>[
      CropAspectRatioPreset.square,
      _Ratio(4, 5, '4:5'),
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
      CropAspectRatioPreset.original,
    ];
    final circle = crop == PhotoCrop.avatar;
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: fixed,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      maxWidth: 2400,
      maxHeight: 2400,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title[crop],
          toolbarColor: BioTheme.backgroundDeep,
          toolbarWidgetColor: Colors.white,
          statusBarLight: false,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: BioTheme.lime,
          cropFrameColor: BioTheme.lime,
          cropStyle: circle ? CropStyle.circle : CropStyle.rectangle,
          lockAspectRatio: fixed != null,
          hideBottomControls: false,
          initAspectRatio: fixed == null ? CropAspectRatioPreset.square : null,
          aspectRatioPresets: fixed == null
              ? postRatios
              : const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: title[crop],
          doneButtonTitle: 'Listo',
          cancelButtonTitle: 'Cancelar',
          cropStyle: circle ? CropStyle.circle : CropStyle.rectangle,
          aspectRatioLockEnabled: fixed != null,
          resetAspectRatioEnabled: fixed == null,
          aspectRatioPickerButtonHidden: fixed != null,
          aspectRatioPresets: fixed == null
              ? postRatios
              : const [CropAspectRatioPreset.square],
        ),
      ],
    );
    return cropped?.path;
  }

  Future<LocalPhoto?> _prepare(XFile file, PhotoCrop? crop) async {
    if (crop == null || kIsWeb) return _read(file);
    final String? path;
    try {
      path = await _crop(file.path, crop);
    } on PlatformException {
      // Si el recortador no abre, se usa la imagen completa.
      return _read(file);
    }
    await deleteTemporaryCapture(file.path);
    if (path == null) return null;
    final name = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return _read(XFile(path, name: '$name.jpg', mimeType: 'image/jpeg'));
  }

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

  /// Elige imágenes; con [crop] cada una pasa por el recortador nativo.
  /// Las que la persona cancela en el recorte se omiten.
  Future<List<LocalPhoto>> pick({
    required bool camera,
    int limit = 1,
    PhotoCrop? crop,
  }) async {
    try {
      if (camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2400,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        if (file == null) return [];
        final photo = await _prepare(file, crop);
        return photo == null ? [] : [photo];
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
      // Se recortan una por una, en el orden elegido.
      final photos = <LocalPhoto>[];
      for (final file in files) {
        final photo = await _prepare(file, crop);
        if (photo != null) photos.add(photo);
      }
      return photos;
    } on PlatformException {
      throw const FeatureUnavailable(
        'No pudimos abrir la cámara o las fotografías. Revisa los permisos de BioJaveriana en los ajustes del dispositivo.',
      );
    }
  }
}
