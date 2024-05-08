import MEGADomain
import MEGAL10n
import UIKit

extension AppDelegate: SaveMediaToPhotoFailureHandling {
    @MainActor
    public func shouldFallbackToMakingOffline() async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: Strings.Localizable.SaveToPhotos.FallbackAlert.title,
                message: Strings.Localizable.SaveToPhotos.FallbackAlert.message,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: Strings.Localizable.ok, style: .default) { _ in
                continuation.resume(returning: true)
            }
            let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { _ in
                continuation.resume(returning: false)
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            UIApplication.mnz_presentingViewController().present(alert, animated: true)
        }
    }
}
