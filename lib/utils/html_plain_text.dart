/// Strips Quill / Frappe HTML descriptions down to readable plain text.
String stripHtmlToPlainText(String? raw) {
  if (raw == null) return '';
  var text = raw.trim();
  if (text.isEmpty) return '';

  // Block tags → line breaks before removing tags.
  text = text.replaceAll(
    RegExp(r'<(br|/p|/div|/li|/h[1-6])[^>]*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');

  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final code = int.tryParse(m.group(1)!);
        if (code == null) return m.group(0)!;
        return String.fromCharCode(code);
      });

  text = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');

  return text.trim();
}
