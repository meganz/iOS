import Foundation
import MEGADomain

struct NodeActionViewModel {
    private var nodeUseCase: NodeUseCaseProtocol
    
    init(nodeUseCase: NodeUseCaseProtocol) {
        self.nodeUseCase = nodeUseCase
    }
}
