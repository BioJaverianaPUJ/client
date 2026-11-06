import '../models/user_profile.dart';
import 'api_client.dart';
import '../models/community.dart';

class UserService {
  const UserService(this._api);

  final ApiClient _api;

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _api.get('/users/me'));

  Future<UserProfile> byId(String id) async =>
      UserProfile.fromJson(await _api.get('/users/${Uri.encodeComponent(id)}'));
  Future<UserProfile> update(Map<String, dynamic> data) async =>
      UserProfile.fromJson(await _api.patch('/users/me', body: data));
  Future<UserProfile> upload(LocalPhoto photo, String type) async =>
      UserProfile.fromJson(await _api.uploadProfile(photo, type));
  Future<UserProfile> removeMedia(String type) async => UserProfile.fromJson(
    await _api.delete('/users/me/media?type=${Uri.encodeQueryComponent(type)}'),
  );
}
