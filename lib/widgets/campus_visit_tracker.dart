import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../state/session_controller.dart';
import '../services/location_service.dart';

/// Reports visits only while the signed-in application is in the foreground.
/// Permission is requested from the camera/map screens, never on login.
class CampusVisitTracker extends StatefulWidget {
  const CampusVisitTracker({
    super.key,
    required this.session,
    required this.child,
  });
  final SessionController session;
  final Widget child;
  @override
  State<CampusVisitTracker> createState() => _CampusVisitTrackerState();
}

class _CampusVisitTrackerState extends State<CampusVisitTracker>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_sync);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();
  void _sync() {
    _timer?.cancel();
    _generation++;
    if (!widget.session.isSignedIn ||
        !widget.session.community.available ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  Future<void> _check() async {
    if (_busy) return;
    _busy = true;
    final generation = _generation;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || generation != _generation || position.accuracy > 5) {
        return;
      }
      final point = LatLng(position.latitude, position.longitude);
      final repo = widget.session.community;
      final zones = await repo.zones();
      if (!mounted || generation != _generation) return;
      final entered = zones
          .where((zone) => LocationService.inside(point, zone.points))
          .toList();
      if (entered.isNotEmpty) {
        await repo.visit(point, position.accuracy);
      }
    } catch (_) {
      // A visit is never credited locally; the next foreground tick can retry.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
