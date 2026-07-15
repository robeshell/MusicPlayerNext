import 'package:flutter_test/flutter_test.dart';
import 'package:sound_player/presentation/screens/source_settings_screen.dart';

void main() {
  test('formats persisted source URIs as readable locations', () {
    expect(
      formatSourceLocation(
        'file:///Users/test/%E9%9F%B3%E4%B9%90/%E5%91%A8%E6%9D%B0%E4%BC%A6',
      ),
      '/Users/test/音乐/周杰伦',
    );
    expect(
      formatSourceLocation(
        'https://dav.example.com/Music/%E5%91%A8%E6%9D%B0%E4%BC%A6/',
      ),
      'dav.example.com/Music/周杰伦',
    );
    expect(
      formatSourceLocation(
        'content://com.android.externalstorage.documents/'
        'tree/primary%3AMusic%2F%E5%91%A8%E6%9D%B0%E4%BC%A6',
      ),
      '内部存储 / Music/周杰伦',
    );
    expect(
      formatSourceLocation('/dav/Music/%E5%91%A8%E6%9D%B0%E4%BC%A6/'),
      '/dav/Music/周杰伦',
    );
  });
}
