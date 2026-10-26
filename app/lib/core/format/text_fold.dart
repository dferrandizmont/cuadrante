/// Lower-cases [text] and drops accents and the diaeresis, so «Alcalá»,
/// «alcala» and «ALCALA» compare equal (the picker's search and the
/// alphabetical order of the communities). `ñ` and `ç` fold to `n` and `c`.
/// Typographic apostrophes fold to `'`, hyphens to a space and the middle dot
/// of Catalan to nothing, so «l’ametlla» finds «L'Ametlla de Mar» and «palau
/// solita» finds «Palau-solità». Pure Dart.
String foldSpanish(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    out.write(_folded[char] ?? char);
  }
  return out.toString();
}

const Map<String, String> _folded = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  '\u2019': "'", // right single quotation mark
  '\u2018': "'", // left single quotation mark
  '\u02bc': "'", // modifier letter apostrophe
  '-': ' ',
  '\u2010': ' ', // hyphen
  '\u2011': ' ', // non-breaking hyphen
  '\u00b7': '', // middle dot
};

/// Orders by [foldSpanish], so accents never decide the order.
int compareSpanish(String a, String b) {
  final byFold = foldSpanish(a).compareTo(foldSpanish(b));
  return byFold != 0 ? byFold : a.compareTo(b);
}
