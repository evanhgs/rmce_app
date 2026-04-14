import 'package:intl/intl.dart';

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final centiseconds =
      (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
  return '$minutes:$seconds:$centiseconds';
}

String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String formatSpeed(double speedKmh) => '${speedKmh.toStringAsFixed(1)} km/h';

String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}
