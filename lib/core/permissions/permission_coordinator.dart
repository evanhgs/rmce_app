import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionStatusSummary {
  const PermissionStatusSummary({
    required this.locationGranted,
    required this.backgroundLocationGranted,
    required this.microphoneGranted,
    required this.notificationsGranted,
    required this.motionGranted,
  });

  final bool locationGranted;
  final bool backgroundLocationGranted;
  final bool microphoneGranted;
  final bool notificationsGranted;
  final bool motionGranted;

  bool get canStartTrackedRun => locationGranted && motionGranted;
}

class PermissionCoordinator {
  Future<PermissionStatusSummary> requestStartupPermissions() async {
    await Permission.locationWhenInUse.request();
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    await Permission.microphone.request();
    if (Platform.isIOS) {
      await Permission.sensors.request();
    }
    return getCurrentSummary();
  }

  Future<bool> ensureLocationPermissionForMaps() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }

    final requested = await Permission.locationWhenInUse.request();
    return requested.isGranted;
  }

  Future<bool> isLocationPermanentlyDenied() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> isLocationServiceEnabled() {
    return Permission.locationWhenInUse.serviceStatus.isEnabled;
  }

  Future<PermissionStatusSummary> getCurrentSummary() async {
    final location = await Permission.location.status;
    final background = Platform.isAndroid
        ? await Permission.locationAlways.status
        : location;
    final microphone = await Permission.microphone.status;
    final notifications = Platform.isAndroid
        ? await Permission.notification.status
        : PermissionStatus.granted;
    final motion = Platform.isIOS
        ? await Permission.sensors.status
        : PermissionStatus.granted;

    return PermissionStatusSummary(
      locationGranted: location.isGranted,
      backgroundLocationGranted: background.isGranted,
      microphoneGranted: microphone.isGranted,
      notificationsGranted: notifications.isGranted,
      motionGranted: motion.isGranted,
    );
  }

  Future<PermissionStatusSummary> requestRunPermissions() async {
    await Permission.locationWhenInUse.request();
    if (Platform.isAndroid) {
      await Permission.locationAlways.request();
      await Permission.notification.request();
    }
    await Permission.microphone.request();
    if (Platform.isIOS) {
      await Permission.sensors.request();
    }
    return getCurrentSummary();
  }
}
