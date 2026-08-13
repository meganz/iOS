import MEGASwift
import UIKit

@MainActor
protocol NotEnoughStorageAlertRouting {
    func showNotEnoughStorage(requiredBytes: UInt64, availableBytes: UInt64)
}

final class NotEnoughStorageAlertRouter: NotEnoughStorageAlertRouting {
    private weak var presenter: UIViewController?

    init(presenter: UIViewController?) {
        self.presenter = presenter
    }

    func showNotEnoughStorage(requiredBytes: UInt64, availableBytes: UInt64) {
        guard let presenter else { return }

        let alertController = UIAlertController(
            title: Constants.title,
            message: String(
                format: Constants.messageFormat,
                String.memoryStyleString(fromByteCount: Int64(clamping: requiredBytes)),
                String.memoryStyleString(fromByteCount: Int64(clamping: availableBytes))
            ),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: Constants.dismissTitle, style: .cancel))

        presenter.present(alertController, animated: true)
    }
}

private extension NotEnoughStorageAlertRouter {
    /// Hardcoded copy until the strings land in Weblate — tracked by IOS-12316.
    enum Constants {
        static let title = "Not enough storage"
        static let messageFormat = "This download needs about %@ of free space, and your device has %@. Free up some space and try again."
        static let dismissTitle = "OK, got it"
    }
}
