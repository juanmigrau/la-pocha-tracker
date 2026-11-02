import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ThemeBloc buildBloc() => ThemeBloc(prefs: prefs);

  group('ThemeBloc', () {
    test('initial state is ThemeMode.system', () {
      expect(buildBloc().state.themeMode, ThemeMode.system);
    });

    blocTest<ThemeBloc, ThemeState>(
      'ThemeStarted emits system when no preference is stored',
      build: buildBloc,
      act: (bloc) => bloc.add(const ThemeStarted()),
      expect: () => [const ThemeState(themeMode: ThemeMode.system)],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeStarted emits stored dark preference',
      setUp: () async {
        await prefs.setString(ThemeBloc.themeModeKey, 'dark');
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ThemeStarted()),
      expect: () => [const ThemeState(themeMode: ThemeMode.dark)],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeStarted emits stored light preference',
      setUp: () async {
        await prefs.setString(ThemeBloc.themeModeKey, 'light');
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ThemeStarted()),
      expect: () => [const ThemeState(themeMode: ThemeMode.light)],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeChanged persists and emits the new mode',
      build: buildBloc,
      act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.dark)),
      expect: () => [const ThemeState(themeMode: ThemeMode.dark)],
      verify: (_) {
        expect(prefs.getString(ThemeBloc.themeModeKey), 'dark');
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeChanged to system persists system',
      build: buildBloc,
      act: (bloc) => bloc.add(const ThemeChanged(ThemeMode.system)),
      expect: () => [const ThemeState(themeMode: ThemeMode.system)],
      verify: (_) {
        expect(prefs.getString(ThemeBloc.themeModeKey), 'system');
      },
    );
  });
}
