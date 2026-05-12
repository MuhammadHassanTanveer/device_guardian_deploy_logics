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
    id: int.tryParse(json["id"]?.toString() ?? "0") ?? 0,
    name: json["name"]?.toString() ?? json["country_name"]?.toString() ?? '',
    code: json["code"]?.toString() ?? json["country_code"]?.toString(),
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
    id: int.tryParse(json["id"]?.toString() ?? "0") ?? 0,
    name: json["name"]?.toString() ?? json["state_name"]?.toString() ?? '',
    countryId: int.tryParse(json["country_id"]?.toString() ?? "0") ?? 0,
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
    id: int.tryParse(json["id"]?.toString() ?? "0") ?? 0,
    name: json["name"]?.toString() ?? json["city_name"]?.toString() ?? '',
    stateId: int.tryParse(json["state_id"]?.toString() ?? "0") ?? 0,
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

