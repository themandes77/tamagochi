import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';

class PetState {
  factory PetState({
    required double hunger,
    required double cleanliness,
    required double energy,
    required double fun,
    required DateTime lastSavedAt,
    PetRules rules = const PetRules(),
  }) {
    _validateFinite(hunger, 'hunger');
    _validateFinite(cleanliness, 'cleanliness');
    _validateFinite(energy, 'energy');
    _validateFinite(fun, 'fun');

    return PetState._(
      hunger: rules.clampNeed(hunger),
      cleanliness: rules.clampNeed(cleanliness),
      energy: rules.clampNeed(energy),
      fun: rules.clampNeed(fun),
      lastSavedAt: lastSavedAt.toUtc(),
    );
  }

  const PetState._({
    required this.hunger,
    required this.cleanliness,
    required this.energy,
    required this.fun,
    required this.lastSavedAt,
  });

  factory PetState.initial({
    required DateTime nowUtc,
    PetRules rules = const PetRules(),
  }) {
    return PetState(
      hunger: rules.initialHunger,
      cleanliness: rules.initialCleanliness,
      energy: rules.initialEnergy,
      fun: rules.initialFun,
      lastSavedAt: nowUtc,
      rules: rules,
    );
  }

  factory PetState.fromJson(
    Map<String, Object?> json, {
    PetRules rules = const PetRules(),
  }) {
    final savedAtValue = json['lastSavedAt'];
    if (savedAtValue is! String) {
      throw const FormatException('lastSavedAt debe ser una fecha ISO 8601.');
    }
    final savedAt = DateTime.tryParse(savedAtValue);
    if (savedAt == null) {
      throw const FormatException('lastSavedAt no contiene una fecha válida.');
    }

    return PetState(
      hunger: _readNeed(json, 'hunger', rules),
      cleanliness: _readNeed(json, 'cleanliness', rules),
      energy: _readNeed(json, 'energy', rules),
      fun: _readNeed(json, 'fun', rules),
      lastSavedAt: savedAt,
      rules: rules,
    );
  }

  final double hunger;
  final double cleanliness;
  final double energy;
  final double fun;
  final DateTime lastSavedAt;

  double get health => healthFor(const PetRules());

  double healthFor(PetRules rules) {
    return rules.healthFor(
      hunger: hunger,
      cleanliness: cleanliness,
      energy: energy,
      fun: fun,
    );
  }

  PetState copyWith({
    double? hunger,
    double? cleanliness,
    double? energy,
    double? fun,
    DateTime? lastSavedAt,
    PetRules rules = const PetRules(),
  }) {
    return PetState(
      hunger: hunger ?? this.hunger,
      cleanliness: cleanliness ?? this.cleanliness,
      energy: energy ?? this.energy,
      fun: fun ?? this.fun,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      rules: rules,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hunger': hunger,
      'cleanliness': cleanliness,
      'energy': energy,
      'fun': fun,
      'lastSavedAt': lastSavedAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetState &&
            hunger == other.hunger &&
            cleanliness == other.cleanliness &&
            energy == other.energy &&
            fun == other.fun &&
            lastSavedAt == other.lastSavedAt;
  }

  @override
  int get hashCode {
    return Object.hash(hunger, cleanliness, energy, fun, lastSavedAt);
  }

  static double _readNeed(
    Map<String, Object?> json,
    String key,
    PetRules rules,
  ) {
    final value = json[key];
    if (value is! num || (value is double && !value.isFinite)) {
      throw FormatException('$key debe ser un número finito.');
    }
    final number = value.toDouble();
    if (number < rules.needMinimum || number > rules.needMaximum) {
      throw FormatException('$key está fuera del intervalo permitido.');
    }
    return number;
  }

  static void _validateFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Debe ser un número finito.');
    }
  }
}
