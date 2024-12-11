import SwiftUI

public struct AdsViewWrapper: UIViewControllerRepresentable {
    
    private(set) public var adsViewController: UIViewController
    
    public init(viewController: UIViewController) {
        self.adsViewController = viewController
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        adsViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
