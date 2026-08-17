import MEGAL10n
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
            title: Strings.Localizable.Link.Download.NotEnoughStorage.title,
            message: Strings.Localizable.Link.Download.NotEnoughStorage.message(
                displaySize(of: requiredBytes),
                displaySize(of: availableBytes)
            ),
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: Strings.Localizable.Link.Download.NotEnoughStorage.Button.dismiss, style: .cancel)
        )

        presenter.present(alertController, animated: true)
    }

    private func displaySize(of bytes: UInt64) -> String {
        String.memoryStyleString(fromByteCount: Int64(clamping: bytes))
    }
}
