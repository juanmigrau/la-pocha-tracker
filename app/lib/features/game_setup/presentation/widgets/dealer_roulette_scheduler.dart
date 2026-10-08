import 'dart:async';
import 'dart:math';

/// Schedules roulette-style highlight ticks across player ids.
///
/// Phases (elapsed from [start]):
/// - 0–1s: ~120ms interval
/// - 1–2s: ~250ms interval
/// - 2–2.5s: ~450ms interval
/// Then lands on [winnerId] and calls [onComplete].
class DealerRouletteScheduler {
  DealerRouletteScheduler({
    required this.playerIds,
    required this.winnerId,
    required this.onHighlight,
    required this.onComplete,
    Random? random,
  }) : _random = random ?? Random() {
    if (playerIds.isEmpty) {
      throw ArgumentError('playerIds must not be empty');
    }
    if (!playerIds.contains(winnerId)) {
      throw ArgumentError('winnerId must be one of playerIds');
    }
  }

  static const Duration totalDuration = Duration(milliseconds: 2500);
  static const Duration fastPhaseEnd = Duration(milliseconds: 1000);
  static const Duration mediumPhaseEnd = Duration(milliseconds: 2000);
  static const Duration fastInterval = Duration(milliseconds: 120);
  static const Duration mediumInterval = Duration(milliseconds: 250);
  static const Duration slowInterval = Duration(milliseconds: 450);

  final List<String> playerIds;
  final String winnerId;
  final void Function(String playerId) onHighlight;
  final void Function() onComplete;
  final Random _random;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  String? _currentHighlight;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _elapsed = Duration.zero;
    _emitTickAndSchedule();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _elapsed = Duration.zero;
    _currentHighlight = null;
  }

  Duration intervalForElapsed(Duration elapsed) {
    if (elapsed < fastPhaseEnd) {
      return fastInterval;
    }
    if (elapsed < mediumPhaseEnd) {
      return mediumInterval;
    }
    return slowInterval;
  }

  void _emitTickAndSchedule() {
    if (_elapsed >= totalDuration) {
      _currentHighlight = winnerId;
      onHighlight(winnerId);
      _timer = null;
      _isRunning = false;
      onComplete();
      return;
    }

    final nextId = _pickRandomPlayerId();
    _currentHighlight = nextId;
    onHighlight(nextId);

    final interval = intervalForElapsed(_elapsed);
    _timer = Timer(interval, () {
      _elapsed += interval;
      _emitTickAndSchedule();
    });
  }

  String _pickRandomPlayerId() {
    if (playerIds.length == 1) {
      return playerIds.first;
    }

    String candidate;
    do {
      candidate = playerIds[_random.nextInt(playerIds.length)];
    } while (candidate == _currentHighlight);
    return candidate;
  }
}
