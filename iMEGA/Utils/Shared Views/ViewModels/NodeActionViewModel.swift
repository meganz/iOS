import Foundation
import MEGADomain

struct NodeActionViewModel {
    private var nodeActionUseCase: NodeActionUseCaseProtocol
    
    init(nodeActionUseCase: NodeActionUseCaseProtocol) {
        self.nodeActionUseCase = nodeActionUseCase
    }
}
