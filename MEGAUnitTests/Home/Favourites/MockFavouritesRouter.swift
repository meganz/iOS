@testable import MEGA
import MEGADomain
import XCTest

final class MockFavouritesRouter: FavouritesRouting {
    var openNode_calledTimes = 0
    var openNodeActions_calledTimes = 0
    
    func openNode(_ nodeHandle: HandleEntity) {
        openNode_calledTimes += 1
    }
    
    func openNodeActions(nodeHandle: HandleEntity, sender: Any) {
        openNodeActions_calledTimes += 1
    }
}
