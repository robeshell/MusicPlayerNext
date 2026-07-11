import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var localDirectoryAccessPlugin: LocalDirectoryAccessPlugin?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    localDirectoryAccessPlugin = LocalDirectoryAccessPlugin(
      messenger: flutterViewController.engine.binaryMessenger,
      window: self)

    super.awakeFromNib()
  }
}

private final class LocalDirectoryAccessPlugin {
  private let channel: FlutterMethodChannel
  private weak var window: NSWindow?
  private var activeURLs: [String: URL] = [:]

  init(messenger: FlutterBinaryMessenger, window: NSWindow) {
    channel = FlutterMethodChannel(
      name: "com.soundplayer.sound_player/local_directory_access",
      binaryMessenger: messenger)
    self.window = window
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  deinit {
    for url in activeURLs.values {
      url.stopAccessingSecurityScopedResource()
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickDirectory":
      pickDirectory(result: result)
    case "restoreDirectory":
      restoreDirectory(call.arguments, result: result)
    case "releaseDirectory":
      releaseDirectory(call.arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickDirectory(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.prompt = "选择"

    let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      do {
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
          includingResourceValuesForKeys: nil,
          relativeTo: nil)
        guard url.startAccessingSecurityScopedResource() else {
          result(self?.grant(
            url: url,
            status: "permissionRequired",
            bookmark: bookmark,
            isStale: false))
          return
        }
        self?.retain(url)
        result(self?.grant(
          url: url,
          status: "available",
          bookmark: bookmark,
          isStale: false))
      } catch {
        result(FlutterError(
          code: "bookmark_creation_failed",
          message: error.localizedDescription,
          details: nil))
      }
    }

    if let window {
      panel.beginSheetModal(for: window, completionHandler: completion)
    } else {
      panel.begin(completionHandler: completion)
    }
  }

  private func restoreDirectory(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let arguments = arguments as? [String: Any],
      let rootURI = arguments["rootUri"] as? String,
      let bookmarkData = arguments["permissionToken"] as? FlutterStandardTypedData
    else {
      result(FlutterError(
        code: "invalid_directory_grant",
        message: "A root URI and security-scoped bookmark are required.",
        details: nil))
      return
    }

    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData.data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale)
      guard url.startAccessingSecurityScopedResource() else {
        result(grant(
          url: url,
          status: "permissionRequired",
          bookmark: bookmarkData.data,
          isStale: isStale))
        return
      }
      retain(url)
      let refreshedBookmark = isStale
        ? try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil)
        : bookmarkData.data
      result(grant(
        url: url,
        status: FileManager.default.fileExists(atPath: url.path)
          ? "available"
          : "unavailable",
        bookmark: refreshedBookmark,
        isStale: isStale))
    } catch {
      let fallbackURL = URL(string: rootURI) ?? URL(fileURLWithPath: rootURI)
      result(grant(
        url: fallbackURL,
        status: "permissionRequired",
        bookmark: bookmarkData.data,
        isStale: false))
    }
  }

  private func releaseDirectory(_ arguments: Any?) {
    guard
      let arguments = arguments as? [String: Any],
      let rootURI = arguments["rootUri"] as? String,
      let url = activeURLs.removeValue(forKey: rootURI)
    else {
      return
    }
    url.stopAccessingSecurityScopedResource()
  }

  private func retain(_ url: URL) {
    let key = url.absoluteString
    if let previous = activeURLs.updateValue(url, forKey: key) {
      previous.stopAccessingSecurityScopedResource()
    }
  }

  private func grant(
    url: URL,
    status: String,
    bookmark: Data,
    isStale: Bool
  ) -> [String: Any] {
    return [
      "rootUri": url.absoluteString,
      "displayName": url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent,
      "status": status,
      "permissionToken": FlutterStandardTypedData(bytes: bookmark),
      "isStale": isStale,
    ]
  }
}
