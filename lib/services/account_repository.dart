import 'api_client.dart';
import 'api_exception.dart';
import 'community_repository.dart';

/// Operaciones sobre la cuenta propia. Esta base informa que no están
/// disponibles; [ApiAccountRepository] las conecta al backend.
class AccountRepository {
  bool get passwordChangeAvailable => false;
  bool get deletionAvailable => false;
  Future<void> changePassword(String current, String next) async =>
      throw const FeatureUnavailable(
        'El cambio de contraseña aún no está disponible.',
      );
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async => throw const FeatureUnavailable(
    'La eliminación de tu cuenta aún no está disponible.',
  );
}

/// RF-40 y RF-41: PATCH /users/me/password y DELETE /users/me.
class ApiAccountRepository extends AccountRepository {
  ApiAccountRepository(this._api);
  final ApiClient _api;

  @override
  bool get passwordChangeAvailable => true;
  @override
  bool get deletionAvailable => true;

  @override
  Future<void> changePassword(String current, String next) async {
    try {
      await _api.patch(
        '/users/me/password',
        body: {'currentPassword': current, 'newPassword': next},
      );
    } on ApiException catch (e) {
      if (e.code == 'INVALID_CURRENT_PASSWORD') {
        throw const FeatureUnavailable('La contraseña actual no es correcta.');
      }
      if (e.code == 'NEW_PASSWORD_SAME_AS_CURRENT') {
        throw const FeatureUnavailable(
          'La nueva contraseña debe ser diferente de la actual.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    // RF-41: el backend confirma la contraseña actual en el mismo DELETE.
    try {
      await _api.delete('/users/me', body: {'password': password});
    } on ApiException catch (e) {
      if (e.code == 'INVALID_CURRENT_PASSWORD') {
        throw const FeatureUnavailable(
          'La contraseña no es correcta. Tu cuenta no se eliminó.',
        );
      }
      rethrow;
    }
  }
}
