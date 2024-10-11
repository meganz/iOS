import MEGAPresentation
import UIKit

public final class MockNavigator: Routing {
    public private(set) var start_calledTimes = 0
    
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {
        start_calledTimes += 1
    }
}
