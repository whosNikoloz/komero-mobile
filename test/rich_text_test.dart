import 'package:flutter_test/flutter_test.dart';
import 'package:komero_mobile/src/core/rich_text.dart';

void main() {
  group('htmlToPlainText', () {
    test('drops tags and leaves readable text', () {
      expect(htmlToPlainText('<p>dsada</p>'), 'dsada');
      expect(
        htmlToPlainText('<p>First</p><p>Second</p>'),
        'First\n\nSecond',
      );
      expect(htmlToPlainText('<p>a<br>b</p>'), 'a\nb');
    });

    test('decodes the entities an editor emits', () {
      expect(htmlToPlainText('<p>Tom&nbsp;&amp;&nbsp;Jerry</p>'), 'Tom & Jerry');
      expect(htmlToPlainText('<p>5&nbsp;&lt;&nbsp;7</p>'), '5 < 7');
      // The zero-width space the storefront pads <br> with must not survive.
      expect(htmlToPlainText('<p>a<br>&#8203;b</p>'), 'a\nb');
    });

    test('keeps lists and emphasis as marks the editor can write back', () {
      expect(htmlToPlainText('<ul><li>one</li><li>two</li></ul>'), '- one\n- two');
      expect(htmlToPlainText('<p>a <strong>bold</strong> word</p>'), 'a **bold** word');
      expect(htmlToPlainText('<p>a <em>soft</em> word</p>'), 'a _soft_ word');
    });

    test('passes plain values through untouched', () {
      expect(htmlToPlainText('just text'), 'just text');
      expect(htmlToPlainText(null), '');
      expect(htmlToPlainText(''), '');
    });
  });

  group('plainTextToHtml', () {
    test('one paragraph per blank-line block', () {
      expect(plainTextToHtml('First\n\nSecond'), '<p>First</p><p>Second</p>');
      expect(plainTextToHtml('a\nb'), '<p>a<br>b</p>');
      expect(plainTextToHtml('   '), '');
    });

    test('escapes markup the operator typed as text', () {
      expect(plainTextToHtml('5 < 7 & rising'), '<p>5 &lt; 7 &amp; rising</p>');
    });

    test('renders the marks the toolbar writes', () {
      expect(plainTextToHtml('a **bold** word'), '<p>a <strong>bold</strong> word</p>');
      expect(plainTextToHtml('a _soft_ word'), '<p>a <em>soft</em> word</p>');
      expect(plainTextToHtml('- one\n- two'), '<ul><li>one</li><li>two</li></ul>');
      // A lone mark is text, not the start of an unclosed tag.
      expect(plainTextToHtml('SKU_42 and 2 * 3'), '<p>SKU_42 and 2 * 3</p>');
    });
  });

  test('text survives the round trip the editor puts it through', () {
    const samples = [
      'dsada',
      'First\n\nSecond',
      'a\nb',
      'Tom & Jerry',
      '5 < 7',
      'a **bold** word',
      'a _soft_ word',
      '- one\n- two',
      'Specs:\n\n- 2.4 GHz\n- **12** months',
    ];

    for (final text in samples) {
      expect(htmlToPlainText(plainTextToHtml(text)), text, reason: text);
    }
  });
}
