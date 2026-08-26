import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import UIKit

@MainActor
protocol AlbumLinkExportRouting: AnyObject {
    /// Writes the photos to the device through the system share sheet, where Save to Files lives.
    func export(photos: [NodeEntity]) async
}

/// Runs the album link's Download button, the same export the file link and folder link Download buttons run.
final class AlbumLinkExportRouter: AlbumLinkExportRouting {
    /// The album link screen, which does not exist yet when the view model that drives the export is built.
    weak var presenter: UIViewController?

    private let nodeProvider: any MEGANodeProviderProtocol
    private let storageChecker: any DeviceStorageChecking
    private let notEnoughStorageAlertRouter: (any NotEnoughStorageAlertRouting)?
    /// Held for the whole export rather than only while it is being set up, because a second run would clear
    /// the staging directory the first one is still filling. A repeated tap is dropped instead.
    private var isExporting = false

    init(
        nodeProvider: some MEGANodeProviderProtocol = PublicAlbumNodeProvider.shared,
        storageChecker: some DeviceStorageChecking = DeviceStorageChecker(
            deviceStorageUseCase: DeviceStorageUseCase(deviceStorageRepository: DeviceStorageRepository.newRepo)
        ),
        notEnoughStorageAlertRouter: (any NotEnoughStorageAlertRouting)? = nil
    ) {
        self.nodeProvider = nodeProvider
        self.storageChecker = storageChecker
        self.notEnoughStorageAlertRouter = notEnoughStorageAlertRouter
    }

    func export(photos: [NodeEntity]) async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        guard let presenter, await confirmEnoughStorage(for: photos) else { return }

        await ExportFileRouter(
            presenter: presenter,
            sender: presenter.view,
            incompleteDownloadAlertRouter: IncompleteDownloadAlertRouter(),
            nodeProvider: nodeProvider
        )
        .export(nodes: photos)?.value
    }

    /// The whole selection is written to the device, so the space question is settled up front instead of
    /// letting the SDK fail photo by photo half way through.
    private func confirmEnoughStorage(for photos: [NodeEntity]) async -> Bool {
        let bytes = photos.reduce(UInt64.zero) { $0 + $1.size }

        switch await storageChecker.verdict(forAdditionalBytes: bytes) {
        case .fits:
            return true
        case let .doesNotFit(requiredBytes, availableBytes):
            let alertRouter = notEnoughStorageAlertRouter ?? NotEnoughStorageAlertRouter(presenter: presenter)
            alertRouter.showNotEnoughStorage(requiredBytes: requiredBytes, availableBytes: availableBytes)
            return false
        }
    }
}
