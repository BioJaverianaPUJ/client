import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/reference_images.dart';
import 'community_widgets.dart';

class SpeciesReferencePhotos extends StatefulWidget {
  const SpeciesReferencePhotos({super.key, required this.name});
  final String name;
  @override
  State<SpeciesReferencePhotos> createState() => _SpeciesReferencePhotosState();
}

class _SpeciesReferencePhotosState extends State<SpeciesReferencePhotos> {
  final _service = ReferenceImages();
  late Future<List<ReferenceImage>> _images = _service.find(widget.name);
  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ReferenceImage>>(
    future: _images,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() => _images = _service.find(widget.name)),
          child: const Text('No se pudo consultar GBIF. Reintentar'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      if (snapshot.data!.isEmpty) {
        return const Text(
          'GBIF no tiene imágenes de referencia reutilizables para esta especie.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imágenes de referencia · GBIF',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Son referencias de la especie, no fotografías de este espécimen del campus.',
          ),
          for (final photo in snapshot.data!) ...[
            const SizedBox(height: 12),
            RemotePhoto(photo.url, height: 180),
            Text(photo.credit),
            Wrap(
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(photo.source),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Ver fuente'),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(photo.license.replaceFirst('http:', 'https:')),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Licencia de la fotografía'),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
