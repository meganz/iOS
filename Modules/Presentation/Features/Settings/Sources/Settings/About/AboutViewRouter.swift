import Foundation
import MEGADomain
import MEGAPresentation
import SwiftUI

public final class AboutViewRouter: NSObject, Routing {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private var aboutViewModel: AboutViewModel
    private var title: String
    
    public init(presenter: UINavigationController?, aboutViewModel: AboutViewModel, title: String) {
        self.presenter = presenter
        self.aboutViewModel = aboutViewModel
        self.title = title
        
        super.init()
    }
    
    public func build() -> UIViewController {
        let aboutView = AboutView(viewModel: self.aboutViewModel)
        let hostingController = UIHostingController(rootView: aboutView)
        baseViewController = hostingController
        baseViewController?.title = title

        return hostingController
    }
    
    public func start() {
        presenter?.pushViewController(build(), animated: true)
    }
}
