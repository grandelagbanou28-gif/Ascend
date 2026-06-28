import 'package:uuid/uuid.dart';

enum FocusMode {
  pomodoro25_5,
  long45_15,
  focus50_10,
  deep90_20,
  libre,
}

extension FocusModeExtension on FocusMode {
  String get displayName {
    switch (this) {
      case FocusMode.pomodoro25_5:
        return '25/5';
      case FocusMode.long45_15:
        return '45/15';
      case FocusMode.focus50_10:
        return '50/10';
      case FocusMode.deep90_20:
        return '90/20';
      case FocusMode.libre:
        return 'Libre';
    }
  }

  String get description {
    switch (this) {
      case FocusMode.pomodoro25_5:
        return '25 min travail / 5 min pause';
      case FocusMode.long45_15:
        return '45 min travail / 15 min pause';
      case FocusMode.focus50_10:
        return '50 min travail / 10 min pause';
      case FocusMode.deep90_20:
        return '90 min travail / 20 min pause';
      case FocusMode.libre:
        return 'Temps libre';
    }
  }

  int get workMinutes {
    switch (this) {
      case FocusMode.pomodoro25_5:
        return 25;
      case FocusMode.long45_15:
        return 45;
      case FocusMode.focus50_10:
        return 50;
      case FocusMode.deep90_20:
        return 90;
      case FocusMode.libre:
        return 0;
    }
  }

  int get breakMinutes {
    switch (this) {
      case FocusMode.pomodoro25_5:
        return 5;
      case FocusMode.long45_15:
        return 15;
      case FocusMode.focus50_10:
        return 10;
      case FocusMode.deep90_20:
        return 20;
      case FocusMode.libre:
        return 0;
    }
  }
}

enum AmbientSound {
  none,
  music,
  whiteNoise,
  rain,
  forest,
  wind,
  ocean,
  lofi,
}

extension AmbientSoundExtension on AmbientSound {
  String get displayName {
    switch (this) {
      case AmbientSound.none:
        return 'Aucun';
      case AmbientSound.music:
        return 'Musique';
      case AmbientSound.whiteNoise:
        return 'Bruit blanc';
      case AmbientSound.rain:
        return 'Pluie';
      case AmbientSound.forest:
        return 'Forêt';
      case AmbientSound.wind:
        return 'Vent';
      case AmbientSound.ocean:
        return 'Océan';
      case AmbientSound.lofi:
        return 'Lo-fi';
    }
  }

  String get icon {
    switch (this) {
      case AmbientSound.none:
        return '🔇';
      case AmbientSound.music:
        return '🎵';
      case AmbientSound.whiteNoise:
        return '📻';
      case AmbientSound.rain:
        return '🌧️';
      case AmbientSound.forest:
        return '🌲';
      case AmbientSound.wind:
        return '💨';
      case AmbientSound.ocean:
        return '🌊';
      case AmbientSound.lofi:
        return '🎧';
    }
  }
}

enum FocusSessionStatus { running, paused, completed, interrupted }

class FocusSession {
  final String id;
  FocusMode mode;
  AmbientSound sound;
  FocusSessionStatus status;
  DateTime startTime;
  DateTime? endTime;
  int plannedMinutes;
  int actualMinutes;
  int breaksTaken;
  int xpEarned;
  String? notes;

  FocusSession({
    String? id,
    required this.mode,
    this.sound = AmbientSound.none,
    this.status = FocusSessionStatus.running,
    DateTime? startTime,
    this.endTime,
    int? plannedMinutes,
    this.actualMinutes = 0,
    this.breaksTaken = 0,
    this.xpEarned = 0,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now(),
        plannedMinutes = plannedMinutes ?? mode.workMinutes;

  double get progression {
    if (plannedMinutes == 0) return 0.0;
    return (actualMinutes / plannedMinutes).clamp(0.0, 1.0);
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.index,
        'sound': sound.index,
        'status': status.index,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'plannedMinutes': plannedMinutes,
        'actualMinutes': actualMinutes,
        'breaksTaken': breaksTaken,
        'xpEarned': xpEarned,
        'notes': notes,
      };

  static FocusSession fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'],
        mode: FocusMode.values[json['mode'] ?? 0],
        sound: AmbientSound.values[json['sound'] ?? 0],
        status: FocusSessionStatus.values[json['status'] ?? 0],
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'])
            : null,
        plannedMinutes: json['plannedMinutes'] ?? 25,
        actualMinutes: json['actualMinutes'] ?? 0,
        breaksTaken: json['breaksTaken'] ?? 0,
        xpEarned: json['xpEarned'] ?? 0,
        notes: json['notes'],
      );

  static int calculateXp(FocusMode mode, int minutes) {
    int baseXp = minutes;
    switch (mode) {
      case FocusMode.pomodoro25_5:
        baseXp = (minutes * 1.0).round();
        break;
      case FocusMode.long45_15:
        baseXp = (minutes * 1.2).round();
        break;
      case FocusMode.focus50_10:
        baseXp = (minutes * 1.3).round();
        break;
      case FocusMode.deep90_20:
        baseXp = (minutes * 1.5).round();
        break;
      case FocusMode.libre:
        baseXp = minutes;
        break;
    }
    return baseXp;
  }
}
