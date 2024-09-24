import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final class QASettingsViewModel {
    private enum Constants {
        static let newVersionAvailableAlertTitle = "New Version Available"
        static let newVersionAvailableMessage = "Version {Version_Placeholder} is available."
        static let updateAlertButtonTitle = "Update"
    }
    
    private let router: any QASettingsRouting
    private let appDistributionUseCase: any AppDistributionUseCaseProtocol
    private var checkForUpdateTask: Task<Void, Never>?
    
    init(
        router: some QASettingsRouting,
        appDistributionUseCase: some AppDistributionUseCaseProtocol
    ) {
        self.router = router
        self.appDistributionUseCase = appDistributionUseCase
    }
    
    deinit {
        checkForUpdateTask?.cancel()
    }
    
    // MARK: - Check for Update
    @discardableResult
    func checkForUpdate() -> Task<Void, Never>? {
        checkForUpdateTask = Task {
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
    
    // MARK: - Clear Standard UserDefaults
    func clearStandardUserDefaults() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            router.showAlert(
                withTitle: "Failed to clear Standard UserDefaults",
                message: "The app bundle identifier is nil",
                actions: [UIAlertAction(title: "OK", style: .default)]
            )
            return
        }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        router.showAlert(
            withTitle: "Success",
            message: "Standard UserDefaults is now cleared!",
            actions: [UIAlertAction(title: "OK", style: .default)]
        )
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
}
