import 'package:flutter_test/flutter_test.dart';
import 'package:komero_mobile/src/core/rich_text.dart';

void main() {
  group('htmlToBlocks', () {
    test('splits text, pictures and video into blocks', () {
      final blocks = htmlToBlocks(
        '<p>Intro</p>'
        '<img src="https://img.komero.ge/a.jpg" alt="">'
        '<p>Between</p>'
        '<div data-iframe-wrapper="true"><div>'
        '<iframe src="https://www.youtube.com/embed/abc123" allowfullscreen></iframe>'
        '</div></div>'
        '<p>Outro</p>',
      );

      expect(blocks.length, 5);
      expect((blocks[0] as TextBlock).text, 'Intro');
      expect((blocks[1] as ImageBlock).url, 'https://img.komero.ge/a.jpg');
      expect((blocks[2] as TextBlock).text, 'Between');
      expect((blocks[3] as VideoBlock).embedUrl, 'https://www.youtube.com/embed/abc123');
      expect((blocks[4] as TextBlock).text, 'Outro');
    });

    test('plain markup is one text block, and nothing is no blocks', () {
      expect(htmlToBlocks('<p>just words</p>').length, 1);
      expect(htmlToBlocks(''), isEmpty);
      expect(htmlToBlocks(null), isEmpty);
      // A tag with no src is dropped rather than becoming an empty picture.
      expect(htmlToBlocks('<p>a</p><img alt="">').length, 1);
    });
  });

  group('blocksToHtml', () {
    test('writes the shapes the web editor parses back', () {
      final html = blocksToHtml(const [
        TextBlock('Intro'),
        ImageBlock('https://img.komero.ge/a.jpg'),
        VideoBlock('https://www.youtube.com/embed/abc123'),
      ]);

      expect(html, startsWith('<p>Intro</p>'));
      expect(html, contains('<img src="https://img.komero.ge/a.jpg"'));
      // The storefront and TipTap both key off the wrapper.
      expect(html, contains('data-iframe-wrapper="true"'));
      expect(html, contains('<iframe src="https://www.youtube.com/embed/abc123"'));
    });

    test('a description survives the round trip the editor puts it through', () {
      const blocks = [
        TextBlock('Specs:\n\n- 2.4 GHz\n- **12** months'),
        ImageBlock('https://img.komero.ge/a.jpg'),
        VideoBlock('https://www.youtube.com/embed/abc123'),
        TextBlock('Tom & Jerry, 5 < 7'),
      ];

      final back = htmlToBlocks(blocksToHtml(blocks));

      expect(back.length, 4);
      expect(
        (back[0] as TextBlock).text,
        'Specs:\n\n- 2.4 GHz\n- **12** months',
        reason: 'paragraph and list come back as the one text block they were',
      );
      expect((back[1] as ImageBlock).url, 'https://img.komero.ge/a.jpg');
      expect((back[2] as VideoBlock).embedUrl, 'https://www.youtube.com/embed/abc123');
      expect((back[3] as TextBlock).text, 'Tom & Jerry, 5 < 7');
    });
  });

  test('a YouTube link becomes a player URL whichever form it is pasted in', () {
    const embed = 'https://www.youtube.com/embed/abc123';

    expect(youtubeEmbedUrl('https://www.youtube.com/watch?v=abc123'), embed);
    expect(youtubeEmbedUrl('https://youtu.be/abc123'), embed);
    expect(youtubeEmbedUrl('https://youtube.com/shorts/abc123'), embed);
    expect(youtubeEmbedUrl(embed), embed);
    // Not YouTube, and not a URL at all: the caller decides what to do.
    expect(youtubeEmbedUrl('https://vimeo.com/123'), isNull);
    expect(youtubeEmbedUrl('nonsense'), isNull);
  });
}
