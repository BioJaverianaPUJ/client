import 'dart:io';

Future<void> deleteTemporaryCapture(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return;
    final temporary = await Directory.systemTemp.resolveSymbolicLinks();
    final resolved = await file.resolveSymbolicLinks();
    // Never delete originals from the gallery or any file outside app cache.
    if (resolved.startsWith('$temporary${Platform.pathSeparator}')) {
      await file.delete();
    }
  } on FileSystemException {
    // The operating system may already have reclaimed the cache file.
  }
}
