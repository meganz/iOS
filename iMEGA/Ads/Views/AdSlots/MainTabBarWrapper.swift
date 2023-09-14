import SwiftUI

struct MainTabBarWrapper: UIViewControllerRepresentable {
    
    private var mainTabBar: MainTabBarController
    
    init(mainTabBar: MainTabBarController) {
        self.mainTabBar = mainTabBar
    }
    
    func makeUIViewController(context: Context) -> MainTabBarController {
        mainTabBar
    }
    
    func updateUIViewController(_ uiViewController: MainTabBarController, context: Context) {}
}
