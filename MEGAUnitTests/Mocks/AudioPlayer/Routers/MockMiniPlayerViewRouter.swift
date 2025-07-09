@testable import MEGA

final class MockMiniPlayerViewRouter: MiniPlayerViewRouting {
    
    typealias DismissCompletion = () -> Void
    
    var dismiss_calledTimes = 0
    var showPlayer_calledTimes = 0
    var showTermsOfServiceViolationAlert_calledTimes = 0
    
    var onDismissCompletion: DismissCompletion?
    
    private let isFolderLinkPresenter: Bool
    
    init(isFolderLinkPresenter: Bool = true) {
        self.isFolderLinkPresenter = isFolderLinkPresenter
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
        onDismissCompletion?()
    }
    
    func showPlayer(node: MEGANode?, filePath: String?) {
        showPlayer_calledTimes += 1
    }
    
    func isAFolderLinkPresenter() -> Bool {
        isFolderLinkPresenter
    }
    
    func showTermsOfServiceViolationAlert() {
        showTermsOfServiceViolationAlert_calledTimes += 1
    }
}
