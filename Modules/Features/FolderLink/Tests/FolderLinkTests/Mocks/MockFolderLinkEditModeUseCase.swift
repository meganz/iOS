import FolderLink
import MEGADomain

final class MockFolderLinkEditModeUseCase: FolderLinkEditModeUseCaseProtocol {
    private let canEnter: Bool
    
    init(canEnter: Bool = false) {
        self.canEnter = canEnter
    }
    
    func canEnterEditModeWhenOpeningFolder(_ nodeHandle: HandleEntity) -> Bool {
        canEnter
    }
}
