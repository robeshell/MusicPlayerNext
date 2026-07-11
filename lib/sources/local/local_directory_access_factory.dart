import 'local_directory_access.dart';
import 'local_directory_access_factory_stub.dart'
    if (dart.library.io) 'local_directory_access_factory_io.dart'
    as platform;

LocalDirectoryAccess createLocalDirectoryAccess() =>
    platform.createLocalDirectoryAccess();
