/// Where the person works: the region (`ES-CT`) and the municipality (INE
/// code) whose holidays they get. Both optional: no region means only the
/// national holidays.
class HolidayPlace {
  const HolidayPlace({this.regionCode, this.municipalityCode});

  static const HolidayPlace none = HolidayPlace();

  final String? regionCode;
  final String? municipalityCode;

  @override
  bool operator ==(Object other) =>
      other is HolidayPlace &&
      other.regionCode == regionCode &&
      other.municipalityCode == municipalityCode;

  @override
  int get hashCode => Object.hash(regionCode, municipalityCode);

  @override
  String toString() => 'HolidayPlace($regionCode, $municipalityCode)';
}
