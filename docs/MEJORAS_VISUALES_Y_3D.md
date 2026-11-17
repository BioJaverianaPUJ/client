# Ajustes visuales y vista del campus

La guía de captura adapta recomendaciones generales de Pl@ntNet e iNaturalist a una única fotografía por observación de BioJaveriana. No implica integración con sus modelos ni garantías de identificación. Los rasgos de hoja (forma, borde y nervaduras), flores y frutos ayudan a documentar la planta; una imagen no permite medir su tamaño real sin escala.

Fuentes:
- https://docs.plantnet.org/en/cookbook/making-a-good-observation/
- https://docs.plantnet.org/en/cookbook/identification-choosing-the-right-species/
- https://help.inaturalist.org/en/support/solutions/articles/151000197160-how-to-make-an-observation-with-the-inaturalist-iphone-app
- https://huggingface.co/imageomics/bioclip-2

La vista 3D es una exploración arquitectónica opcional; el mapa operativo conserva ubicación, filtros y observaciones. Usa MapLibre y el fondo configurado de CARTO. Los edificios se incluyen localmente en assets/campus-buildings.geojson: extracción de OpenStreetMap del área del campus, licencia ODbL, atribución © OpenStreetMap contributors, https://www.openstreetmap.org/copyright. Los identificadores OSM se conservan. Consulta fuente: https://api.openstreetmap.org/api/0.6/map?bbox=-74.0675,4.6238,-74.0600,4.6332 .

Se incluyen 248 contornos: 233 con altura etiquetada en OSM, 4 estimados a partir de pisos × 3 metros y 11 con altura ilustrativa de 9 metros. No constituyen un levantamiento oficial ni un modelo BIM. El terreno se muestra plano. No se usan modelos de la Universidad ni datos IDECA con permisos pendientes. No hay consultas Overpass durante el uso; el mapa base conserva sus condiciones y consumo de solicitudes.
