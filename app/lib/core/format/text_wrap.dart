/// Word joiner: no line break at this point, and it takes no width.
const String wordJoiner = '⁠';

/// No-break space.
const String noBreakSpace = ' ';

final RegExp _timeRange = RegExp(r'(\d{1,2}(?::\d{2})?)([–-])(?=\d)');
final RegExp _tagThenTime = RegExp(r'\b(\p{Lu}{1,3}) (?=\d)', unicode: true);

/// [text] with every time range («22–06», «07:30–15») and the short name of
/// a shift before it («N 22–06») made unbreakable, so a narrow line breaks
/// between the items of a list («M 08–15, T 15–22») and never inside one:
/// the en dash allows a break after it, which left «22–» at the end of a line
/// and «08» at the start of the next (H-T01-7). Only joins characters; the
/// visible text is the same.
String keepTimeRangesTogether(String text) => text
    .replaceAllMapped(_timeRange, (m) => '${m[1]}${m[2]}$wordJoiner')
    .replaceAllMapped(_tagThenTime, (m) => '${m[1]}$noBreakSpace');
