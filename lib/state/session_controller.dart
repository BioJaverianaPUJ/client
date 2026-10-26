import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/auth_session.dart';
import '../models/registration_data.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';
import '../services/user_service.dart';

enum SessionStatus { signedOut, signedIn }

class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient api,
    required this.storage,
    this.autoRefresh = true,
  })  : _api = api,
        _auth = AuthService(api),
        _users = UserService(api) {
    _api.onUnauthorized = _handleUnauthorized;
    if (autoRefresh) {
      _lifecycle = AppLifecycleListener(onResume: _handleResume);
    }
  }

  factory SessionController.create() =>
      SessionController(api: ApiClient(), storage: SecureSessionStorage());

  static const _refreshBefore = Duration(minutes: 5);
  static const _retryDelay = Duration(minutes: 1);

  final ApiClient _api;
  final SessionStorage storage;
  final AuthService _auth;
  final UserService _users;
  final bool autoRefresh;

  AppLifecycleListener? _lifecycle;
  Timer? _refreshTimer;

  SessionStatus _status = SessionStatus.signedOut;
  AuthSession? _session;
  UserProfile? _user;
  bool _expired = false;

  SessionStatus get status => _status;
  bool get isSignedIn => _status == SessionStatus.signedIn;
  AuthSession? get session => _session;
  UserProfile? get user => _user;
  bool get sessionExpired => _expired;

  Future<void> restore() async {
    final stored = await storage.read();

    if (stored == null || stored.isExpired(margin: const Duration(minutes: 1))) {
      await storage.clear();
      _expired = stored != null;
      _setSignedOut();
      return;
    }

    _activate(stored);
    notifyListeners();
    unawaited(_loadProfileQuietly());
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _auth.login(email: email, password: password);
    await _start(session);
  }

  Future<void> register(RegistrationData data) async {
    final session = await _auth.register(data);
    await _start(session);
  }

  Future<void> reloadProfile() async {
    _user = await _users.me();
    notifyListeners();
  }

  Future<void> logout() async {
    _expired = false;
    await _end();
  }

  void clearExpiredNotice() => _expired = false;

  Future<void> _start(AuthSession session) async {
    await storage.write(session);
    _expired = false;
    _activate(session);
    notifyListeners();
    await _loadProfileQuietly();
  }

  void _activate(AuthSession session) {
    _session = session;
    _api.token = session.token;
    _status = SessionStatus.signedIn;
    _scheduleRefresh();
  }

  Future<void> _loadProfileQuietly() async {
    try {
      await reloadProfile();
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized) {
        return;
      }
    }
  }

  void _scheduleRefresh([Duration? delay]) {
    _refreshTimer?.cancel();
    final session = _session;
    if (!autoRefresh || session == null) {
      return;
    }

    final untilRefresh = delay ??
        session.expiresAt
            .subtract(_refreshBefore)
            .difference(DateTime.now().toUtc());

    _refreshTimer = Timer(
      untilRefresh.isNegative ? Duration.zero : untilRefresh,
      _refresh,
    );
  }

  Future<void> _refresh() async {
    final current = _session;
    if (current == null) {
      return;
    }

    try {
      final renewed = await _auth.refresh();
      if (_session?.token != current.token) {
        return;
      }
      await storage.write(renewed);
      _activate(renewed);
      notifyListeners();
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized ||
          current.isExpired(margin: const Duration(seconds: 30))) {
        await _expire();
      } else {
        _scheduleRefresh(_retryDelay);
      }
    }
  }

  void _handleResume() {
    final session = _session;
    if (session == null) {
      return;
    }
    if (session.isExpired()) {
      unawaited(_expire());
    } else if (session.isExpired(margin: _refreshBefore)) {
      unawaited(_refresh());
    }
  }

  void _handleUnauthorized() {
    if (isSignedIn) {
      unawaited(_expire());
    }
  }

  Future<void> _expire() async {
    _expired = true;
    await _end();
  }

  Future<void> _end() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _api.token = null;
    _session = null;
    _user = null;
    await storage.clear();
    _setSignedOut();
  }

  void _setSignedOut() {
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lifecycle?.dispose();
    _api.onUnauthorized = null;
    super.dispose();
  }
}
