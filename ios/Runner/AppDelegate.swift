import AppIntents
import Flutter
import UIKit
// For FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    DaylyAssistant.shared.installQuickActions()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // A cold start from a home-screen quick action carries the item here.
  // Same configuration as Info.plist ("flutter"); only the item is read.
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if let item = options.shortcutItem {
      _ = DaylyAssistant.shared.handle(item)
    }
    return UISceneConfiguration(name: "flutter", sessionRole: connectingSceneSession.role)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Reminder "Snooze" runs in a background isolate that needs the plugins.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DaylyAssistant") {
      DaylyAssistant.shared.attach(registrar)
    }
  }
}

/// Siri / Shortcuts / quick actions → Dart (lib/services/assistant).
/// Commands queue here until Dart takes them, so a cold start loses nothing.
final class DaylyAssistant: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = DaylyAssistant()

  private var channel: FlutterMethodChannel?
  private var pending: [[String: String]] = []

  func attach(_ registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dayly/assistant", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      if call.method == "take" {
        result(self.pending)
        self.pending.removeAll()
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    registrar.addSceneDelegate(self)
  }

  func send(_ command: [String: String]) {
    pending.append(command)
    channel?.invokeMethod("ping", arguments: nil)
  }

  func installQuickActions() {
    func item(_ type: String, _ title: String, _ symbol: String) -> UIApplicationShortcutItem {
      UIApplicationShortcutItem(
        type: type,
        localizedTitle: NSLocalizedString(title, comment: ""),
        localizedSubtitle: nil,
        icon: UIApplicationShortcutIcon(systemImageName: symbol),
        userInfo: nil
      )
    }
    UIApplication.shared.shortcutItems = [
      item("voice", "Add by voice", "mic.fill"),
      item("plan", "My day", "calendar"),
      item("focus", "Focus", "timer"),
    ]
  }

  func handle(_ item: UIApplicationShortcutItem) -> Bool {
    switch item.type {
    case "voice": send(["action": "voice"])
    case "plan": send(["action": "open", "route": "/plan"])
    case "focus": send(["action": "open", "route": "/focus"])
    default: return false
    }
    return true
  }

  @objc(windowScene:performActionForShortcutItem:completionHandler:)
  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool {
    let handled = handle(shortcutItem)
    if handled { completionHandler(true) }
    return handled
  }
}

// MARK: - Siri & Shortcuts (App Intents, iOS 16+)

struct AddToDaylyIntent: AppIntent {
  static var title: LocalizedStringResource = "Add to Dayly"
  static var description = IntentDescription(
    "Adds a task, expense, shopping item or note. Times and amounts are understood.")
  static var openAppWhenRun = true

  @Parameter(title: "What", requestValueDialog: IntentDialog("What should I add?"))
  var text: String

  @MainActor
  func perform() async throws -> some IntentResult {
    DaylyAssistant.shared.send(["action": "add", "text": text])
    return .result()
  }
}

struct SpeakToDaylyIntent: AppIntent {
  static var title: LocalizedStringResource = "Speak to Dayly"
  static var description = IntentDescription("Opens Dayly listening, so you can say what to add.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    DaylyAssistant.shared.send(["action": "voice"])
    return .result()
  }
}

struct ShowMyDayIntent: AppIntent {
  static var title: LocalizedStringResource = "Show my day"
  static var description = IntentDescription("Opens today's plan.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    DaylyAssistant.shared.send(["action": "open", "route": "/plan"])
    return .result()
  }
}

struct StartFocusIntent: AppIntent {
  static var title: LocalizedStringResource = "Start focus"
  static var description = IntentDescription("Opens the focus timer.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    DaylyAssistant.shared.send(["action": "open", "route": "/focus"])
    return .result()
  }
}

/// Ready-made Siri phrases (no setup needed); translations in
/// tr.lproj/AppShortcuts.strings.
struct DaylyShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddToDaylyIntent(),
      phrases: [
        "Add to \(.applicationName)",
        "Add something to \(.applicationName)",
        "Note in \(.applicationName)",
      ]
    )
    AppShortcut(
      intent: SpeakToDaylyIntent(),
      phrases: ["Speak to \(.applicationName)", "Talk to \(.applicationName)"]
    )
    AppShortcut(
      intent: ShowMyDayIntent(),
      phrases: ["Show my day in \(.applicationName)", "What's my plan in \(.applicationName)"]
    )
    AppShortcut(
      intent: StartFocusIntent(),
      phrases: ["Start focus in \(.applicationName)", "Focus with \(.applicationName)"]
    )
  }
}
