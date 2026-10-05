import 'package:equatable/equatable.dart';

class GameCuriosities extends Equatable {
  const GameCuriosities({
    required this.riskiestPlayerId,
    required this.riskiestPlayerName,
    required this.mostConservativePlayerId,
    required this.mostConservativePlayerName,
  });

  final String? riskiestPlayerId;
  final String? riskiestPlayerName;
  final String? mostConservativePlayerId;
  final String? mostConservativePlayerName;

  const GameCuriosities.empty()
      : riskiestPlayerId = null,
        riskiestPlayerName = null,
        mostConservativePlayerId = null,
        mostConservativePlayerName = null;

  @override
  List<Object?> get props => [
        riskiestPlayerId,
        riskiestPlayerName,
        mostConservativePlayerId,
        mostConservativePlayerName,
      ];
}
