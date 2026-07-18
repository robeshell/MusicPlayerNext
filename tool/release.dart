import 'dart:io';

const _knownPlatforms = {'android', 'ios', 'macos', 'windows', 'web'};

Future<void> main(List<String> arguments) async {
  final options = _ReleaseOptions.parse(arguments);
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('Run this command from the Reverie repository root.');
    exitCode = 64;
    return;
  }

  final originalPubspec = await pubspec.readAsString();
  final current = _ReleaseVersion.read(originalPubspec);
  final release = options.bump ? current.nextPatch() : current;
  final platforms = options.platforms.isEmpty
      ? _defaultPlatformsForHost()
      : options.platforms;
  _validatePlatforms(platforms);

  stdout.writeln(
    'Reverie ${current.name} → ${release.name} '
    '(internal build ${release.buildNumber})',
  );
  stdout.writeln('Platforms: ${platforms.join(', ')}');
  if (options.dryRun) return;

  if (options.bump) {
    await pubspec.writeAsString(release.applyTo(originalPubspec));
  }

  try {
    final dist = Directory('dist');
    await dist.create(recursive: true);
    for (final platform in platforms) {
      await _buildPlatform(platform, release, dist);
    }
  } catch (_) {
    if (options.bump) await pubspec.writeAsString(originalPubspec);
    stderr.writeln(
      'Release failed; pubspec.yaml was restored to ${current.name}.',
    );
    rethrow;
  }

  stdout.writeln('Release ${release.name} completed. Artifacts are in dist/.');
}

class _ReleaseOptions {
  const _ReleaseOptions({
    required this.bump,
    required this.dryRun,
    required this.platforms,
  });

  factory _ReleaseOptions.parse(List<String> arguments) {
    var bump = true;
    var dryRun = false;
    final platforms = <String>[];
    for (final argument in arguments) {
      switch (argument) {
        case '--no-bump':
          bump = false;
        case '--dry-run':
          dryRun = true;
        case '--help' || '-h':
          stdout.writeln(
            'Usage: dart run tool/release.dart [platform ...] [options]\n'
            'Platforms: android ios macos windows web all\n'
            'Options:\n'
            '  --no-bump  Build the current version without incrementing it.\n'
            '  --dry-run  Print the next version without changing or building.',
          );
          exit(0);
        case 'all':
          platforms
            ..clear()
            ..addAll(_defaultPlatformsForHost());
        default:
          if (!_knownPlatforms.contains(argument)) {
            throw FormatException('Unknown release argument: $argument');
          }
          if (!platforms.contains(argument)) platforms.add(argument);
      }
    }
    return _ReleaseOptions(bump: bump, dryRun: dryRun, platforms: platforms);
  }

  final bool bump;
  final bool dryRun;
  final List<String> platforms;
}

class _ReleaseVersion {
  const _ReleaseVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.buildNumber,
  });

  factory _ReleaseVersion.read(String pubspec) {
    final match = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    if (match == null) {
      throw const FormatException('pubspec.yaml has no valid x.y.z version.');
    }
    return _ReleaseVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      buildNumber: int.tryParse(match.group(4) ?? '') ?? 0,
    );
  }

  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  String get name => '$major.$minor.$patch';

  _ReleaseVersion nextPatch() => _ReleaseVersion(
    major: major,
    minor: minor,
    patch: patch + 1,
    buildNumber: buildNumber + 1,
  );

  String applyTo(String pubspec) {
    return pubspec.replaceFirst(
      RegExp(r'^version:\s*[^\r\n]+', multiLine: true),
      'version: $name+$buildNumber',
    );
  }
}

List<String> _defaultPlatformsForHost() {
  if (Platform.isMacOS) return ['android', 'ios', 'macos', 'web'];
  if (Platform.isWindows) return ['android', 'windows', 'web'];
  return ['android', 'web'];
}

void _validatePlatforms(List<String> platforms) {
  if (platforms.isEmpty) {
    throw const FormatException('Select at least one release platform.');
  }
  if (platforms.contains('ios') && !Platform.isMacOS) {
    throw UnsupportedError('iOS releases require macOS.');
  }
  if (platforms.contains('macos') && !Platform.isMacOS) {
    throw UnsupportedError('macOS releases require macOS.');
  }
  if (platforms.contains('windows') && !Platform.isWindows) {
    throw UnsupportedError('Windows releases require Windows.');
  }
}

Future<void> _buildPlatform(
  String platform,
  _ReleaseVersion version,
  Directory dist,
) async {
  stdout.writeln('\nBuilding $platform ${version.name}...');
  switch (platform) {
    case 'android':
      await _flutterBuild('appbundle', version);
      await _flutterBuild('apk', version);
      await _copyArtifact(
        'build/app/outputs/bundle/release/app-release.aab',
        '${dist.path}/reverie-${version.name}-android.aab',
      );
      await _copyArtifact(
        'build/app/outputs/flutter-apk/app-release.apk',
        '${dist.path}/reverie-${version.name}-android.apk',
      );
    case 'ios':
      await _flutterBuild('ios', version, extra: ['--no-codesign']);
      final packageRoot = Directory(
        'build/release_package/ios-${version.name}',
      );
      if (packageRoot.existsSync()) await packageRoot.delete(recursive: true);
      await packageRoot.create(recursive: true);
      await _run('ditto', [
        'build/ios/iphoneos/Runner.app',
        '${packageRoot.path}/Payload/Runner.app',
      ]);
      await _run('ditto', [
        '-c',
        '-k',
        '--sequesterRsrc',
        '--keepParent',
        'Payload',
        File(
          '${dist.path}/reverie-${version.name}-ios-unsigned.zip',
        ).absolute.path,
      ], workingDirectory: packageRoot.path);
    case 'macos':
      await _flutterBuild('macos', version);
      await _run('ditto', [
        '-c',
        '-k',
        '--sequesterRsrc',
        '--keepParent',
        'build/macos/Build/Products/Release/Reverie.app',
        '${dist.path}/reverie-${version.name}-macos.zip',
      ]);
    case 'windows':
      await _flutterBuild('windows', version);
      final output = File(
        '${dist.path}/reverie-${version.name}-windows.zip',
      ).absolute.path;
      await _run('powershell', [
        '-NoProfile',
        '-Command',
        'Compress-Archive -Force -Path '
            '"build/windows/x64/runner/Release/*" -DestinationPath "$output"',
      ]);
    case 'web':
      await _flutterBuild(
        'web',
        version,
        extra: ['--base-href', '/MusicPlayerNext/'],
      );
      final output = File(
        '${dist.path}/reverie-${version.name}-web.zip',
      ).absolute.path;
      if (Platform.isWindows) {
        await _run('powershell', [
          '-NoProfile',
          '-Command',
          'Compress-Archive -Force -Path "build/web/*" '
              '-DestinationPath "$output"',
        ]);
      } else {
        await _run('zip', [
          '-q',
          '-r',
          output,
          'web',
        ], workingDirectory: 'build');
      }
  }
}

Future<void> _flutterBuild(
  String target,
  _ReleaseVersion version, {
  List<String> extra = const [],
}) {
  return _run('flutter', [
    'build',
    target,
    '--release',
    '--build-name=${version.name}',
    '--build-number=${version.buildNumber}',
    ...extra,
  ]);
}

Future<void> _copyArtifact(String source, String destination) async {
  final file = File(source);
  if (!file.existsSync()) throw StateError('Missing release artifact: $source');
  await file.copy(destination);
  stdout.writeln('Created $destination');
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Exited with code $code',
      code,
    );
  }
}
