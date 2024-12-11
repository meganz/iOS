import SwiftUI

public struct MainTabBarWrapper: UIViewControllerRepresentable {
    
    private(set) public var mainTabBar: UITabBarController
    
    public init(mainTabBar: UITabBarController) {
        self.mainTabBar = mainTabBar
        self.loadTabBarView()
    }
    
    public func makeUIViewController(context: Context) -> UITabBarController {
        mainTabBar
    }
    
    public func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
    
    private func loadTabBarView() {
        _ = mainTabBar.view
    }
}
