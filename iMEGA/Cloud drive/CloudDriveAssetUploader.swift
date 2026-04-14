import Foundation
import MediaImport
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASwift
import Photos
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class CloudDriveAssetUploader: AssetUploader {
    private let store: MEGAStore
    private weak var presenter: UIViewController?
    private let metadataUseCase: any MetadataUseCaseProtocol
    private let uploadFileUseCase: any UploadFileUseCaseProtocol
    private var preparingOverlay: MediaImportOverlay?
    private var preparingViewModel: MediaImportProgressViewModel?

    init(
        store: MEGAStore = .shareInstance(),
        presenter: UIViewController? = nil,
        metadataUseCase: some MetadataUseCaseProtocol = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        ),
        uploadFileUseCase: some UploadFileUseCaseProtocol = UploadFileUseCase(
            uploadFileRepository: UploadFileRepository(sdk: .shared),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            nodeRepository: NodeRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo
        )
    ) {
        self.store = store
        self.presenter = presenter
        self.metadataUseCase = metadataUseCase
        self.uploadFileUseCase = uploadFileUseCase
    }

    // MARK: - Legacy Upload Flow

    func upload(assets: [PHAsset], to handle: MEGAHandle) {
        guard !assets.isEmpty else { return }

        assets.forEach { asset in
            store.insertUploadTransfer(
                withLocalIdentifier: asset.localIdentifier,
                parentNodeHandle: handle
            )
        }

        Helper.startPendingUploadTransferIfNeeded()
    }

    // MARK: - New Upload Flow

    func importFromPhotos(
        results: [PHPickerResult],
        to parentNode: NodeEntity
    ) async {
        MEGALogDebug("[Asset upload] items to upload: \(results.count)")

        showPreparingUI(totalCount: results.count)

        let failedCount = await processImport(results: results, parentNode: parentNode)

        dismissPreparingUI()

        if failedCount > 0 {
            showErrorAlert(failedCount: failedCount)
        }
    }

    // MARK: - Prepare

    private func prepareItems(
        from results: [PHPickerResult]
    ) -> AnyAsyncSequence<MediaImportProgressEntity> {
        let repo = MediaImportRepository(
            destinationDirectory: FileCacheRepository.newRepo.tempUploadURL
        )
        return PrepareMediaImportUseCase(
            itemProviders: results.map(\.itemProvider),
            repository: repo
        ).prepareItems()
    }

    // MARK: - Upload

    private func enqueueUpload(url: URL, parentNode: NodeEntity) async {
        let uploadURL = resolveNameCollision(for: url, inParent: parentNode.handle)

        var appData: String?
        if let formattedCoordinate = await metadataUseCase.formattedCoordinate(forFilePath: uploadURL.path) {
            appData = formattedCoordinate
        }

        let uploadOptions = UploadOptionsEntity(
            appData: appData,
            pitagTrigger: .picker,
            pitagTarget: parentNode.isInShare ? .incomingShare : .cloudDrive
        )

        uploadFileUseCase.uploadFile(
            uploadURL,
            toParent: parentNode.handle,
            uploadOptions: uploadOptions,
            start: nil,
            progress: nil,
            completion: nil
        )
    }

    private func resolveNameCollision(for url: URL, inParent parentHandle: HandleEntity) -> URL {
        let originalName = url.lastPathComponent
        let resolvedName = uploadFileUseCase.resolvedFileName(originalName, inParent: parentHandle)

        guard resolvedName != originalName else { return url }

        let renamedURL = url.deletingLastPathComponent().appendingPathComponent(resolvedName)
        do {
            try FileManager.default.moveItem(at: url, to: renamedURL)
            return renamedURL
        } catch {
            MEGALogError("[Asset upload] Failed to rename file for collision: \(error.localizedDescription)")
            return url
        }
    }

    // MARK: - Orchestration

    /// Prepares picker results and enqueues each staged file for upload.
    /// Failures are accumulated, not thrown — a single bad item does not
    /// prevent the remaining items from uploading.
    /// - Returns: The number of items that failed to prepare.
    private func processImport(
        results: [PHPickerResult],
        parentNode: NodeEntity
    ) async -> Int {
        var lastProgress: MediaImportProgressEntity?

        for await progress in prepareItems(from: results) {
            MEGALogDebug("[Asset upload] Progress: \(progress.fractionCompleted) (\(progress.completedCount)/\(progress.totalCount))")

            if let error = progress.latestError {
                MEGALogError("[Asset upload] Failed to prepare item: \(error.localizedDescription)")
            }

            if let url = progress.latestPreparedURL {
                await enqueueUpload(url: url, parentNode: parentNode)
            }

            updatePreparingUI(progress: progress)
            lastProgress = progress
        }

        return lastProgress?.failedCount ?? 0
    }

    // MARK: - UI

    private func showPreparingUI(totalCount: Int) {
        let viewModel = MediaImportProgressViewModel(totalCount: totalCount)
        preparingViewModel = viewModel
        preparingOverlay = MediaImportOverlay(viewModel: viewModel, presenter: presenter)
        preparingOverlay?.show()
        TransfersWidgetViewController.sharedTransfer().progressView?.hideWidget(widgetFobidden: true)
    }

    private func updatePreparingUI(progress: MediaImportProgressEntity) {
        preparingViewModel?.progress = progress.fractionCompleted
        preparingViewModel?.completedCount = progress.completedCount
    }

    private func dismissPreparingUI() {
        preparingOverlay?.dismiss()
        preparingOverlay = nil
        preparingViewModel = nil
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
    }

    private func showErrorAlert(failedCount: Int) {
        guard let presenter else { return }

        let message = Strings.Localizable.Photos.Upload.Prepare.error(failedCount)

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default))
        presenter.present(alert, animated: true)
    }
}
