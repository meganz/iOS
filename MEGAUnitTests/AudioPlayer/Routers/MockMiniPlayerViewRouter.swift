@testable import MEGA

final class MockMiniPlayerViewRouter: MiniPlayerViewRouting {
    
    var dismiss_calledTimes = 0
    var showPlayer_calledTimes = 0
    
    private let isFolderLinkPresenter: Bool
    
    init(isFolderLinkPresenter: Bool = true) {
        self.isFolderLinkPresenter = isFolderLinkPresenter
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showPlayer(node: MEGANode?, filePath: String?) {
        showPlayer_calledTimes += 1
    }
    
    func isAFolderLinkPresenter() -> Bool {
        isFolderLinkPresenter
    }
}
