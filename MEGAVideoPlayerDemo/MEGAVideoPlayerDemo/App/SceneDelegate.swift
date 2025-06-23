import SwiftUI

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var secondaryWindow: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            setupSecondaryWindow(in: windowScene)
        }
    }

    func setupSecondaryWindow(in scene: UIWindowScene) {
        let secondaryWindow = PassthroughWindow(windowScene: scene)
        let secondaryViewController = UIHostingController(
            rootView: SecondarySceneView(viewModel: DependencyInjection.secondarySceneViewModel)
        )
        secondaryViewController.view.backgroundColor = UIColor.clear
        secondaryWindow.rootViewController = secondaryViewController
        secondaryWindow.isHidden = false
        self.secondaryWindow = secondaryWindow
    }
}

// MARK: - SecondaryScene

private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }

        return rootViewController?.view == hitView ? nil : hitView
    }
}

