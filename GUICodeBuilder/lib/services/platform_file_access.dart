export 'platform_file_access_stub.dart'
    if (dart.library.io) 'platform_file_access_io.dart'
    if (dart.library.html) 'platform_file_access_web.dart';
