import 'community_repository.dart';

class AccountRepository {
  bool get passwordChangeAvailable => false;
  bool get deletionAvailable => false;
  Future<void> changePassword(String current, String next) async =>
      throw const FeatureUnavailable(
        'El cambio de contraseña aún no está disponible.',
      );
  Future<void> deleteAccount() async => throw const FeatureUnavailable(
    'La eliminación de tu cuenta aún no está disponible.',
  );
}
