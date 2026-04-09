// Location models for Country, State, City

class CountryModel {
  final int id;
  final String name;
  final String? code;

  CountryModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    code: json["code"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "code": code,
  };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StateModel {
  final int id;
  final String name;
  final int countryId;

  StateModel({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) => StateModel(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    countryId: json["country_id"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "country_id": countryId,
  };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CityModel {
  final int id;
  final String name;
  final int stateId;

  CityModel({
    required this.id,
    required this.name,
    required this.stateId,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    stateId: json["state_id"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "state_id": stateId,
  };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

