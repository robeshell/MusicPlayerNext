import 'local_directory_access.dart';
import 'unsupported_local_directory_access.dart';

LocalDirectoryAccess createLocalDirectoryAccess() =>
    const UnsupportedLocalDirectoryAccess();
