import UIKit

/// Delegate of the app's only window scene (`UIApplicationSupportsMultipleScenes` is off).
///
/// The scene manifest names the `Launch` storyboard, so UIKit creates the window and its initial
/// root view controller exactly as it did before scenes. This delegate hands that window to
/// `AppDelegate`, which keeps owning the root view controller, and forwards the per-scene entry
/// points to the handlers `AppDelegate` already has.
///
/// App-wide life-cycle work (chat background status, background tasks, badge, privacy cover) is
/// deliberately *not* forwarded from here: UIKit calls a scene delegate only for that scene's own
/// transitions, and on iOS 26 and earlier the system connects a second, non-interactive scene while
/// an external display is mirrored. `AppDelegate` observes the `UIApplication` notifications
/// instead, which reflect the app as a whole.
@objc(SceneDelegate)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// Nil under the unit-test host, which runs with `TestingAppDelegate`.
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    // MARK: - Connection

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard scene is UIWindowScene, let window, let appDelegate else { return }

        appDelegate.sceneDidConnect(with: window, launchURL: connectionOptions.urlContexts.first?.url)

        // On a cold launch these no longer arrive through `launchOptions`; the scene carries them.
        // A notification tap is delivered through `UNUserNotificationCenterDelegate` on either path.
        connectionOptions.urlContexts.forEach { appDelegate.handleOpenURL($0.url) }
        connectionOptions.userActivities.forEach { appDelegate.handleContinueUserActivity($0) }
        if let shortcutItem = connectionOptions.shortcutItem {
            appDelegate.handleColdLaunchShortcutItem(shortcutItem)
        }
    }

    // MARK: - Entry points while running

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { appDelegate?.handleOpenURL($0.url) }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        appDelegate?.handleContinueUserActivity(userActivity)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let appDelegate else {
            completionHandler(false)
            return
        }
        appDelegate.handleShortcutItem(shortcutItem, completionHandler: completionHandler)
    }
}
