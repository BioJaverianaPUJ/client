import 'package:flutter/material.dart';
import '../../theme/bio_theme.dart';
import '../../widgets/community_widgets.dart';

/// Versión de la política que acepta el usuario al registrarse (RF-03).
/// Cambiarla cuando se modifique el texto, para conservar prueba de qué
/// versión aceptó cada persona.
const dataPolicyVersion = '1.0 · 22 de noviembre de 2026';

/// Correo al que los titulares envían consultas y reclamos (Ley 1581, art. 8).
/// Completar con el correo oficial del proyecto antes de la entrega.
const dataPolicyContact = '';

const _sections = <(String, String)>[
  (
    '1. Responsable del tratamiento',
    'BioJaveriana es un proyecto de grado del Grupo 8 de Ingeniería de Sistemas de la Pontificia Universidad Javeriana, sede Bogotá. El equipo del proyecto es responsable del tratamiento de los datos personales que recoge la aplicación, conforme a la Ley Estatutaria 1581 de 2012 y al Decreto 1377 de 2013.',
  ),
  (
    '2. Datos que recogemos',
    '• Datos de tu cuenta: nombre de usuario, nombres, apellidos, género, correo electrónico y contraseña. La contraseña se guarda cifrada con una función de hash y nunca en texto claro.\n'
        '• Imágenes de perfil: foto de perfil y banner, si decides subirlos.\n'
        '• Observaciones: la fotografía que tomas, la ubicación del dispositivo en el momento de la captura, la fecha y el resultado del reconocimiento de la especie.\n'
        '• Visitas a zonas del campus: tu ubicación se consulta solo con la aplicación abierta, para registrar visitas a zonas verdes o de interés. No se consulta en segundo plano.\n'
        '• Contenido de la comunidad: publicaciones, imágenes, comentarios, votos, reacciones y denuncias.\n'
        '• Experiencia, misiones y logros obtenidos en la aplicación.',
  ),
  (
    '3. Para qué usamos tus datos',
    '• Crear y administrar tu cuenta e iniciar tu sesión.\n'
        '• Identificar las especies de tus fotografías y verificar tus observaciones con los especímenes oficiales del campus.\n'
        '• Mostrar tus observaciones y zonas en el mapa, y calcular tu experiencia, misiones y logros.\n'
        '• Publicar en el feed el contenido que tú decidas compartir.\n'
        '• Moderar la comunidad: atender denuncias y aplicar sanciones.\n'
        '• Apoyar el estudio de la biodiversidad del campus con datos agregados.\n'
        'No vendemos tus datos ni los usamos con fines publicitarios.',
  ),
  (
    '4. Qué ven los demás',
    'En tu perfil público, otras personas ven tu nombre de usuario, tu foto, tu banner, tu experiencia, tu nivel, tus logros y tus publicaciones. Tus nombres, apellidos, correo, género y las observaciones que no compartas son privados. El administrador consulta tus datos solo para gestionar la plataforma.',
  ),
  (
    '5. Servicios que intervienen',
    'Tus datos se guardan en el servidor del proyecto y la comunicación viaja cifrada (TLS). Las imágenes se almacenan en un servicio de almacenamiento de objetos. Las fotografías de las observaciones se procesan en el servicio de reconocimiento del proyecto. Las imágenes de referencia de especies provienen de GBIF y el mapa usa teselas de OpenStreetMap y CARTO; a estos servicios no se envían tus datos personales.',
  ),
  (
    '6. Mayoría de edad',
    'BioJaveriana está dirigida a personas mayores de 18 años. Al aceptar esta política declaras que eres mayor de edad. La aplicación no verifica tu edad.',
  ),
  (
    '7. Tus derechos',
    'Como titular de los datos puedes: conocer, actualizar y rectificar tus datos; solicitar prueba de esta autorización; ser informado sobre el uso que se les da; revocar la autorización y pedir la supresión de tus datos; acceder a ellos de forma gratuita, y presentar quejas ante la Superintendencia de Industria y Comercio. Puedes actualizar tus datos desde «Editar perfil» y eliminar tu cuenta desde la configuración del perfil; al eliminarla se borran tus observaciones, fotografías, publicaciones y comentarios.',
  ),
  (
    '8. Conservación y vigencia',
    'Conservamos tus datos mientras tu cuenta esté activa. Si la eliminas, se borran tus datos asociados; los votos, reacciones y denuncias que hiciste se conservan sin identificarte. Esta política rige desde su publicación y te avisaremos si cambia.',
  ),
];

/// Política de tratamiento de datos personales. Devuelve `true` si la
/// persona la acepta desde el botón inferior.
class DataPolicyScreen extends StatelessWidget {
  const DataPolicyScreen({super.key, this.showAccept = true});
  final bool showAccept;

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Tratamiento de datos',
    illustration: '',
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              const Text(
                'Política de tratamiento de datos personales',
                style: TextStyle(
                  color: BioTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Versión $dataPolicyVersion',
                style: TextStyle(color: BioTheme.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              for (final (title, body) in _sections) ...[
                Text(
                  title,
                  style: const TextStyle(
                    color: BioTheme.lime,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: BioTheme.textSecondary,
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                '9. Contacto',
                style: TextStyle(
                  color: BioTheme.lime,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dataPolicyContact.isEmpty
                    ? 'Para consultas y reclamos sobre tus datos, comunícate con el equipo del proyecto BioJaveriana.'
                    : 'Para consultas y reclamos sobre tus datos, escribe a $dataPolicyContact. Responderemos las consultas en máximo 10 días hábiles y los reclamos en máximo 15 días hábiles.',
                style: const TextStyle(
                  color: BioTheme.textSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (showAccept)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Leí y acepto la política'),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
