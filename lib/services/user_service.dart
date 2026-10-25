import '../models/user_profile.dart';
import 'api_client.dart';

class UserService {
  const UserService(this._api);

  final ApiClient _api;

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _api.get('/users/me'));
}
