import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({required this._prefs}) : super(const ThemeState()) {
    on<ThemeStarted>(_onStarted);
    on<ThemeChanged>(_onChanged);
  }

  static const String themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  Future<void> _onStarted(
    ThemeStarted event,
    Emitter<ThemeState> emit,
  ) async {
    emit(ThemeState(themeMode: _themeModeFromPrefs()));
  }

  Future<void> _onChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await _prefs.setString(themeModeKey, _themeModeToString(event.mode));
    emit(ThemeState(themeMode: event.mode));
  }

  ThemeMode _themeModeFromPrefs() {
    final stored = _prefs.getString(themeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
