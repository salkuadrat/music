import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cm;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

String? _currentUrl;
String? _currentFile;

/// For pre downloading cover image
Future<String> download(String url) async {
  if (_currentUrl != null && _currentFile != null && url == _currentUrl) {
    return _currentFile!;
  }

  Directory? directory = await getTemporaryDirectory();

  if (_currentUrl != null) {
    File file = getTempFile(directory, _currentUrl!);

    try {
      await file.delete();
    } catch (e) {
      print('Cannot delete ${file.path}');
    }
  }

  File file = await cm.DefaultCacheManager().getSingleFile(url);
  File tmpFile = getTempFile(directory, url);

  await tmpFile.writeAsBytes(await file.readAsBytes());

  String filename = basename(tmpFile.path);

  _currentUrl = url;
  _currentFile = filename;
  print('download: $filename');
  return filename;
}

/// preparing temporary file for cover image
File getTempFile(Directory directory, String coverUrl) {
  String filename = md5.convert(utf8.encode(coverUrl)).toString();
  print('getTempFile: $filename');
  return File('${directory.path}/$filename.jpg');
}
