import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

@MainActor
@objc final class HomeViewModel: NSObject {
    
    private let shareUseCase: any ShareUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    init(
        shareUseCase: any ShareUseCaseProtocol,
        tracker: some AnalyticsTracking
    ) {
        self.shareUseCase = shareUseCase
        self.tracker = tracker
    }
    
    func openShareFolderDialog(forNode node: MEGANode, router: HomeRouter?) {
        Task {
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: [node.toNodeEntity()])
                router?.didTap(on: .shareFolder(node))
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Analytics tracker
    
    func trackHomeScreenEvent() {
        tracker.trackAnalyticsEvent(with: HomeScreenEvent())
    }
    
    func didStartSearchSession() {
        tracker.trackAnalyticsEvent(with: HomeScreenSearchMenuToolbarEvent())
    }
    
    func didTapStartConversationButton() {
        tracker.trackAnalyticsEvent(with: IOSStartConversationButtonEvent())
    }
    
    func didTapUploadFilesButton() {
        tracker.trackAnalyticsEvent(with: IOSUploadFilesButtonEvent())
    }
    
    func trackHideNodeAction() {
        tracker.trackAnalyticsEvent(with: HideNodeMenuItemEvent())
    }
}
