/// Product descriptions are stored as HTML — the web admin edits them in a
/// TipTap editor (`commerce/components/editor/wysiwyg/text-custom.tsx`) and the
/// storefront renders them as markup
/// (`commerce/components/commerce/product/collapsible-description.tsx`).
///
/// The phone edits the same HTML, as a short list of blocks: text, a picture,
/// an embedded video. Text carries the three marks a product description
/// actually uses — `**bold**`, `_italic_`, `- ` for a list item — which the
/// editor's toolbar writes and its field renders live, so nobody types a tag
/// (`widgets/rich_editor.dart`).
///
/// Pictures and videos are written in the shapes the web editor's own nodes
/// emit, so a description touched on a phone still opens as an image and a
/// video there rather than as stripped text.
library;

// ─────────────────────────────────────────────────── text ↔ markup

/// HTML → the text a person meant to write.
///
/// Bold and italic keep their marks, list items become `- ` lines, block ends
/// become blank lines, `<br>` a single newline; every other tag is dropped.
/// Entities are decoded, because `&amp;nbsp;` on screen is exactly the leak
/// this is here to stop.
String htmlToPlainText(String? html) {
  final raw = html ?? '';

  if (raw.isEmpty) return '';

  // No tags and no entities means it was never markup — a value typed on an
  // older build, or by this editor. Hand it back untouched rather than
  // normalising someone's whitespace for no reason.
  if (!raw.contains('<') && !raw.contains('&')) return raw;

  var text = raw
      .replaceAll(RegExp(r'</?(strong|b)\s*>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'</?(em|i)\s*>', caseSensitive: false), '_')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      // The closing tag is where a block break actually belongs, so it is the
      // one that marks.
      .replaceAll(RegExp(r'</(p|div|h[1-6]|tr|blockquote)\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '- ')
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');

  text = _decodeEntities(text);

  return text
      // Three or more newlines is the editor's own padding, not structure.
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .trim();
}

/// The text a person wrote → HTML the storefront renders the same way.
///
/// One `<p>` per paragraph, a `<ul>` for a run of `- ` lines, `<br>` for a
/// single line break inside a paragraph, and `<strong>`/`<em>` for the inline
/// marks. Nothing cleverer: this is the inverse of [htmlToPlainText], not a
/// markdown parser.
String plainTextToHtml(String text) {
  final trimmed = text.trim();

  if (trimmed.isEmpty) return '';

  final blocks = trimmed
      .replaceAll('\r\n', '\n')
      .split(RegExp(r'\n\s*\n'))
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty);

  final out = StringBuffer();

  for (final block in blocks) {
    final lines = block.split('\n');

    // A block where every line is a bullet is a list. A block where only some
    // are stays a paragraph — splitting it would reorder what the operator
    // typed, and they can always leave a blank line to mean two blocks.
    if (lines.every((line) => bulletMark.hasMatch(line))) {
      out.write('<ul>');

      for (final line in lines) {
        out.write('<li>${_inline(line.replaceFirst(bulletMark, ''))}</li>');
      }

      out.write('</ul>');

      continue;
    }

    out.write('<p>${lines.map(_inline).join('<br>')}</p>');
  }

  return out.toString();
}

/// `- ` or `• ` at the start of a line. The bullet glyph is accepted because
/// that is what an older build of this editor wrote into descriptions.
final bulletMark = RegExp(r'^\s*[-•]\s+');

/// `**bold**`, with the marks. The editor paints these runs bold as they are
/// typed, which is why the pattern lives here next to the HTML that consumes
/// it rather than in the widget.
final boldMark = RegExp(r'\*\*(\S(?:.*?\S)?)\*\*');

/// `_italic_`, with the marks. Both marks need non-space inside them, so a
/// lone `_` in a SKU or a `**` used as a divider is left alone instead of
/// swallowing the rest of the line.
final italicMark = RegExp(r'_(\S(?:[^_]*\S)?)_');

/// Escape first, then apply the marks: a `<` the operator typed stays text,
/// and `**` and `_` survive escaping untouched.
String _inline(String line) => _escape(line)
    .replaceAllMapped(boldMark, (m) => '<strong>${m[1]}</strong>')
    .replaceAllMapped(italicMark, (m) => '<em>${m[1]}</em>');

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// The entities a rich-text editor actually emits, plus numeric escapes.
/// `&amp;` is unescaped last, so `&amp;lt;` does not turn into a tag.
String _decodeEntities(String s) {
  var out = s
      .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'&quot;', caseSensitive: false), '"')
      .replaceAll(RegExp(r'&apos;', caseSensitive: false), "'")
      .replaceAll(RegExp(r'&#39;'), "'")
      .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
      .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>');

  out = out.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) {
      final code = int.tryParse(m[1]!);

      // Zero-width space: the storefront injects one after every <br> so the
      // line keeps its height. It is invisible, so it must not reach a text
      // field where it would sit in the middle of a word.
      if (code == null || code == 8203) return '';

      return String.fromCharCode(code);
    },
  );

  return out.replaceAll(RegExp(r'&amp;', caseSensitive: false), '&');
}

// ─────────────────────────────────────────────── blocks ↔ markup

/// One piece of a description. A description is a short list of these, which is
/// all the structure a phone needs to offer: paragraphs, a picture, a video.
sealed class DescriptionBlock {
  const DescriptionBlock();
}

/// Text, with the inline marks in it.
class TextBlock extends DescriptionBlock {
  const TextBlock(this.text);

  final String text;

  TextBlock withText(String next) => TextBlock(next);
}

/// A picture, already uploaded — [url] is what the storefront will load.
class ImageBlock extends DescriptionBlock {
  const ImageBlock(this.url);

  final String url;
}

/// An embedded video. [embedUrl] is the player URL that goes in the iframe,
/// which for YouTube is not the URL anyone copies from the address bar — see
/// [youtubeEmbedUrl].
class VideoBlock extends DescriptionBlock {
  const VideoBlock(this.embedUrl);

  final String embedUrl;
}

/// Picture and video tags, wherever they sit in the markup. Matched directly
/// rather than by walking the tree: the web editor wraps an iframe in two
/// styled divs and an image sometimes in a link, and none of that wrapping
/// changes what the block is.
final _mediaTag = RegExp(
  r'<(img|iframe)\b[^>]*>',
  caseSensitive: false,
);

final _srcAttr = RegExp(r'''\bsrc\s*=\s*("([^"]*)"|'([^']*)')''', caseSensitive: false);

/// HTML → the blocks the editor shows. Anything that is not a picture or a
/// video becomes text, so an unknown tag degrades to its words instead of
/// disappearing.
List<DescriptionBlock> htmlToBlocks(String? html) {
  final raw = html ?? '';

  if (raw.trim().isEmpty) return const [];

  final blocks = <DescriptionBlock>[];
  var cursor = 0;

  void addText(String markup) {
    final text = htmlToPlainText(markup);

    if (text.isNotEmpty) blocks.add(TextBlock(text));
  }

  for (final m in _mediaTag.allMatches(raw)) {
    addText(raw.substring(cursor, m.start));
    cursor = m.end;

    final tag = m[0]!;
    final src = _srcAttr.firstMatch(tag);
    final url = (src?[2] ?? src?[3] ?? '').trim();

    if (url.isEmpty) continue;

    blocks.add(
      m[1]!.toLowerCase() == 'img'
          ? ImageBlock(url)
          : VideoBlock(youtubeEmbedUrl(url) ?? url),
    );
  }

  addText(raw.substring(cursor));

  return blocks;
}

/// The blocks → HTML, in the shapes the web editor's nodes emit (`image-node`
/// and `iframe-node` in `commerce/components/editor/wysiwyg/`), so what the
/// phone writes is what that editor parses back.
String blocksToHtml(List<DescriptionBlock> blocks) {
  final out = StringBuffer();

  for (final block in blocks) {
    switch (block) {
      case TextBlock(:final text):
        out.write(plainTextToHtml(text));

      case ImageBlock(:final url):
        out.write(
          '<img src="${_attr(url)}" alt="" data-align="center" '
          'style="display:block;margin:0 auto" '
          'class="rounded-lg border border-slate-200 max-w-full h-auto my-2">',
        );

      case VideoBlock(:final embedUrl):
        out.write(
          '<div data-iframe-wrapper="true" style="display:flex;justify-content:center">'
          '<div style="position:relative;display:inline-block;width:100%;max-width:100%">'
          '<iframe src="${_attr(embedUrl)}" frameborder="0" scrolling="no" '
          'style="border:none;overflow:hidden;display:block;width:100%;height:400px" '
          'allowfullscreen></iframe>'
          '</div></div>',
        );
    }
  }

  return out.toString();
}

String _attr(String value) =>
    value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');

/// A YouTube link as the player URL an iframe needs, or null if it is not a
/// YouTube link — a plain embed URL from anywhere else is used as given.
///
/// Mirrors `toYouTubeEmbedUrl` in the web editor's `iframe-node.tsx`: watch
/// links, youtu.be, shorts and already-embed URLs all have to work, because
/// those are what someone pastes.
String? youtubeEmbedUrl(String input) {
  final uri = Uri.tryParse(input.trim());

  if (uri == null || !uri.hasScheme) return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  final segments = uri.pathSegments;

  if ((host == 'youtube.com' || host == 'youtube-nocookie.com') &&
      segments.length >= 2 &&
      segments.first == 'embed') {
    return uri.toString();
  }

  if (host == 'youtu.be' && segments.isNotEmpty) {
    return 'https://www.youtube.com/embed/${segments.first}';
  }

  if (host == 'youtube.com') {
    if (uri.path == '/watch') {
      final id = uri.queryParameters['v'];

      if (id != null && id.isNotEmpty) return 'https://www.youtube.com/embed/$id';
    }

    if (segments.length >= 2 && segments.first == 'shorts') {
      return 'https://www.youtube.com/embed/${segments[1]}';
    }
  }

  return null;
}
