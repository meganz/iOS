import MEGADomain
import MEGAL10n
import SwiftUI

final class QASettingsViewModel {
    private enum Constants {
        static let newVersionAvailableAlertTitle = "New Version Available"
        static let newVersionAvailableMessage = "Version {Version_Placeholder} is available."
        static let updateAlertButtonTitle = "Update"
    }
    
    private let router: any QASettingsRouting
    private let fingerprintUseCase: any SecureFingerprintUseCaseProtocol
    private let appDistributionUseCase: any AppDistributionUseCaseProtocol
    private var checkForUpdateTask: Task<Void, Never>?
    
    init(
        router: some QASettingsRouting,
        fingerprintUseCase: some SecureFingerprintUseCaseProtocol,
        appDistributionUseCase: some AppDistributionUseCaseProtocol
    ) {
        self.router = router
        self.fingerprintUseCase = fingerprintUseCase
        self.appDistributionUseCase = appDistributionUseCase
    }
    
    deinit {
        checkForUpdateTask?.cancel()
    }
    
    // MARK: - Check for Update
    @discardableResult
    func checkForUpdate() -> Task<Void, Never>? {
        checkForUpdateTask = Task { @MainActor in
            do {
                if let releaseEntity = try await appDistributionUseCase.checkForUpdate() {
                    show(release: releaseEntity)
                } else {
                    MEGALogDebug("No new release available")
                }
            } catch {
                show(error: error)
            }
        }
        return checkForUpdateTask
    }
    
    private func show(release: AppDistributionReleaseEntity) {
        let message = Constants
            .newVersionAvailableMessage
            .replacingOccurrences(
                of: "{Version_Placeholder}",
                with: "\(release.displayVersion)(\(release.buildVersion))"
            )
        
        let updateAction = UIAlertAction(title: Constants.updateAlertButtonTitle, style: .default) { _ in
            UIApplication.shared.open(release.downloadURL)
        }
        let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil)
        
        router.showAlert(
            withTitle: Constants.newVersionAvailableAlertTitle,
            message: message,
            actions: [updateAction, cancelAction]
        )
    }
    
    private func show(error: some Error) {
        router.showAlert(withError: error)
    }
    
    // MARK: - Fingerprint flag
    func fingerprintVerificationFlagStatus() -> String {
        fingerprintUseCase.secureFingerprintStatus().lowercased()
    }
}
