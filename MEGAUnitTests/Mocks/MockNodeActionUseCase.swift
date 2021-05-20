@testable import MEGA

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevel: NodeAccessTypeEntity = .unknown
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        return nodeAccessLevel
    }
    
    func downloadToOffline(nodeHandle: MEGAHandle) { }
}
