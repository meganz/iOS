@testable import MEGA
import MEGADomain

final class MockMoveToRubbishBinViewModel: MoveToRubbishBinViewModelProtocol {
    var calledNodes: [NodeEntity] = []
    
    func moveToRubbishBin(nodes: [NodeEntity]) {
        calledNodes = nodes
    }
}
