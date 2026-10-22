import 'dart:async';

/// Tik tepat di setiap pergantian menit sejak [origin] (jam mulai turnamen), bukan tiap 60 detik sejak dibuat.
/// Sisa booking dihitung dalam menit penuh sejak `createdAt`, jadi kotak jam, daftar "Prioritas main di R…", dan
/// hasil "Buat R…" selalu memakai menit yang sama; `Timer.periodic` bisa tertinggal sampai 59 detik (logic.md §10).
class MinuteTicker {
  final DateTime Function() _clock;
  final DateTime? Function() _origin;
  final void Function() _onTick;
  Timer? _timer;

  MinuteTicker({
    required DateTime Function() clock,
    required DateTime? Function() origin,
    required void Function() onTick,
  }) : _clock = clock,
       _origin = origin,
       _onTick = onTick {
    _schedule();
  }

  void _schedule() {
    final origin = _origin();
    // Belum ada turnamen: cukup cek lagi semenit lagi.
    final intoMinute = origin == null ? 0 : _clock().difference(origin).inMilliseconds % Duration.millisecondsPerMinute;
    _timer = Timer(Duration(milliseconds: Duration.millisecondsPerMinute - intoMinute), () {
      _onTick();
      _schedule();
    });
  }

  void cancel() => _timer?.cancel();
}
