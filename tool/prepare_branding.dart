import 'dart:io';
import 'package:image/image.dart' as img;

// Platform assets use the original artwork, resized proportionally on a canvas.
void main() {
  const root = 'assets/branding';
  final tree = img.decodePng(File('$root/yggdrasil-original.png').readAsBytesSync())!;
  final wordmark = img.decodePng(File('$root/biojaveriana-original.png').readAsBytesSync())!;
  void canvas(String name, img.Image source, int width, int height, int artworkWidth, {bool transparent = false}) {
    final output = img.Image(width: width, height: height, numChannels: 4);
    img.fill(output, color: img.ColorRgba8(245, 247, 237, transparent ? 0 : 255));
    final scaled = img.copyResize(source, width: artworkWidth,
      height: (source.height * artworkWidth / source.width).round(), interpolation: img.Interpolation.cubic);
    img.compositeImage(output, scaled, dstX: (width - scaled.width) ~/ 2, dstY: (height - scaled.height) ~/ 2);
    File('$root/$name.png').writeAsBytesSync(img.encodePng(output));
  }
  canvas('launcher', tree, 1024, 1024, 700);
  canvas('launcher-foreground', tree, 1024, 1024, 600, transparent: true);
  canvas('splash-android12', tree, 1152, 1152, 600, transparent: true);
  canvas('splash-wordmark', wordmark, 960, 320, 960, transparent: true);
  canvas('splash-branding', wordmark, 800, 320, 800, transparent: true);
}
