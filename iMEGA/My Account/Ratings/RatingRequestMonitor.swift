import Foundation
import MEGADomain
import MEGAFoundation
import MEGASDKRepo
import StoreKit

@objc final class RatingRequestMonitor: NSObject {
    private let sdk: MEGASdk
    private let debouncer = Debouncer(delay: 0.7, dispatchQueue: .global(qos: .utility))
    
    private lazy var currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    private lazy var baseConditionUseCase: any RatingRequestBaseConditionsUseCaseProtocol
    = RatingRequestBaseConditionsUseCase(
        preferenceUserCase: PreferenceUseCase.default,
        accountRepo: AccountRepository.newRepo,
        currentAppVersion: currentAppVersion
    )
    private lazy var shareUseCase: some ShareUseCaseProtocol = ShareUseCase(
        shareRepository: ShareRepository(sdk: sdk),
        filesSearchRepository: FilesSearchRepository(sdk: sdk),
        nodeRepository: NodeRepository(
            sdk: sdk,
            sharedFolderSdk: .shared,
            nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk)
        )
    )
    
    @objc init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
    }
    
    @objc func startMonitoring() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTransferFinishedNotification(_:)), name: Notification.Name.MEGATransferFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveShareCreatedNotification(_:)), name: Notification.Name.MEGAShareCreated, object: nil)
    }
    
    @objc func didReceiveTransferFinishedNotification(_ notification: Notification) {
        guard let transfer = notification.userInfo?[MEGATransferUserInfoKey] as? MEGATransfer else {
            return
        }
        
        if transfer.type == .download || transfer.type == .upload {
            debouncer.start {
                if RatingRequesting.transfer.shouldRequestRating(TransferMoment(transfer: transfer.toTransferEntity()), self.baseConditionUseCase) {
                    self.requestReview()
                }
            }
        }
    }
    
    @objc func didReceiveShareCreatedNotification(_ notification: Notification) {
        if RatingRequesting.share.shouldRequestRating(ShareMoment(shareUseCase: shareUseCase), baseConditionUseCase) {
            requestReview()
        }
    }
    
    func requestReview() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
            self.baseConditionUseCase.saveLastRequestedAppVersion(self.currentAppVersion)
        }
    }
}
