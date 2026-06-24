import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##,##0', 'en_IN');

String fmtAmount(double amount) => '₹${_fmt.format(amount)}';

List<String> parseTags(String? note) {
  if (note == null || note.isEmpty) return [];
  return RegExp(r'#(\w+)').allMatches(note).map((m) => m.group(1)!.toLowerCase()).toList();
}
