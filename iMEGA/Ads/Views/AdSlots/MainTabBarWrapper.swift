import SwiftUI

struct MainTabBarWrapper: UIViewControllerRepresentable {
    
    private(set) var mainTabBar: UITabBarController
    
    init(mainTabBar: UITabBarController) {
        _ = mainTabBar.view
        self.mainTabBar = mainTabBar
    }
    
    func makeUIViewController(context: Context) -> UITabBarController {
        mainTabBar
    }
    
    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {}
}
