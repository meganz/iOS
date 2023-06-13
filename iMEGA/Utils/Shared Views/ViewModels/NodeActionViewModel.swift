import Foundation
import MEGADomain

struct NodeActionViewModel {
    private var nodeUseCase: any NodeUseCaseProtocol
    
    init(nodeUseCase: any NodeUseCaseProtocol) {
        self.nodeUseCase = nodeUseCase
    }
}
