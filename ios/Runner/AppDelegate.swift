import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications needs this to receive taps and to present
    // anything while the app is in the foreground. FlutterAppDelegate already
    // conforms to the protocol; it just is not wired up by default. This has
    // to happen here (rather than once the Flutter engine is up) because
    // UNUserNotificationCenter delivery decisions can't wait for the scene.
    UNUserNotificationCenter.current().delegate = self

    // Plugin registration now happens in didInitializeImplicitFlutterEngine,
    // once the implicit engine (and its scene) is actually ready. See
    // https://flutter.dev/to/uiscene-migration
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
