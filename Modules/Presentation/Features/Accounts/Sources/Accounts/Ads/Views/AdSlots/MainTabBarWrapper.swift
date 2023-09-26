import SwiftUI

public struct MainTabBarWrapper: UIViewControllerRepresentable {
    
    private(set) public var mainTabBar: UITabBarController
    
    public init(mainTabBar: UITabBarController) {
        self.mainTabBar = mainTabBar
    }
    
    public func makeUIViewController(context: Context) -> UITabBarController {
        mainTabBar
    }
    
    public func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
