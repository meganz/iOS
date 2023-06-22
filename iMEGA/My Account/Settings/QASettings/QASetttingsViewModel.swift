import SwiftUI
@preconcurrency import FirebaseAppDistribution

final class QASettingsViewModel {
    private enum Constants {
        static let newVersionAvailableAlertTitle = "New Version Available"
        static let newVersionAvailableMessage = "Version {Version_Placeholder} is available."
        static let updateAlertButtonTitle = "Update"
    }
    
    private let router: any QASettingsRouting
    private var checkForUpdateTask: Task<Void, Never>?
    
    init(router: some QASettingsRouting) {
        self.router = router
    }
    
    deinit {
        checkForUpdateTask?.cancel()
    }
    
    // MARK: - Check for Update
    func checkForUpdate() {
        checkForUpdateTask = Task { @MainActor in
            do {
                if let release = try await AppDistribution.appDistribution().checkForUpdate() {
                    show(release: release)
                } else {
                    MEGALogDebug("No new release available")
                }
            } catch {
                show(error: error)
            }
        }
    }
    
    private func show(release: AppDistributionRelease) {
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
    
    private func show(error: Error) {
        router.showAlert(withError: error)
    }
    
    // MARK: - Fingerprint flag
    func fingerprintVerificationFlagStatus() -> String {
        SharedSecureFingerprintManager().secureFingerprintStatus()
    }
}
