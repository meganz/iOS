import MEGAAppPresentation
import UIKit

public final class MockRouter: Routing {
    private let viewController: UIViewController?
    public private(set) var startCalled = 0
    
    public init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }
    
    public func build() -> UIViewController {
        viewController ?? UIViewController()
    }
    
    public func start() {
        startCalled += 1
    }
}
