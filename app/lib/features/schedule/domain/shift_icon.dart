/// The icons a shift type can carry next to its code (docs/paridad.md, A8).
///
/// A **curated set of keys**, never emojis: the key is what is stored (database
/// and `.cuadrante` file) and each platform draws it with its own symbol set
/// (`AppIcons`, in the presentation layer). A key this build does not know (a
/// file from a newer app, a damaged row) reads as `null`: the shift type
/// simply has no icon, nothing else breaks.
///
/// Keys are stable for ever: add new ones at the end, never rename or remove
/// one that shipped.
enum ShiftIcon {
  sun,
  moon,
  sunrise,
  hospital,
  ambulance,
  police,
  fire,
  factory,
  truck,
  plane,
  school,
  home,
  beach,
  bed,
  star,
  heart,
  coffee,
  book,
  money,
  alert,
  phone,
  car,
  train,
  bus,
  shop,
  tool,
  baby,
  sport,
  party,
  medical;

  /// The stored key.
  String get key => name;

  /// The icon stored as [key]; `null` for `null`, an empty text or a key that
  /// is not in the set.
  static ShiftIcon? fromKey(String? key) {
    if (key == null) return null;
    for (final icon in values) {
      if (icon.name == key) return icon;
    }
    return null;
  }

  /// The keys that are valid, in the order of the set.
  static List<String> get keys => [for (final icon in values) icon.name];
}
