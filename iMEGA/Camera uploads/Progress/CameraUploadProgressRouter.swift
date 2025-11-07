import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAPreference
import MEGARepo
import SwiftUI

struct CameraUploadProgressRouter: Routing {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let assetRepository = CameraUploadAssetRepository(
            cameraUploadRecordStore: CameraUploadRecordManager.shared())
        let preferenceRepository = PreferenceRepository.newRepo
        let viewModel = CameraUploadProgressTableViewModel(
            cameraUploadProgressUseCase: CameraUploadProgressUseCase(
                cameraUploadAssetRepository: assetRepository,
                transferProgressRepository: CameraUploadTransferProgressRepository.shared),
            cameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCase(
                cameraUploadAssetRepository: assetRepository,
                cameraAssetTypeRepository: CameraAssetTypeRepository(),
                preferenceRepository: preferenceRepository),
            photoLibraryThumbnailUseCase: PhotoLibraryThumbnailUseCase(
                photoLibraryThumbnailRepository: PhotoLibraryThumbnailRepository()),
            paginationManager: CameraUploadPaginationManager(
                pageSize: 30,
                lookAhead: 4,
                lookBehind: 4,
                queuedCameraUploadsUseCase: QueuedCameraUploadsUseCase(
                    cameraUploadAssetRepository: assetRepository,
                    preferenceRepository: preferenceRepository)))
        
        let hostingController = UIHostingController(
            rootView: CameraUploadProgressView(viewModel: viewModel))
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.view.backgroundColor = TokenColors.Background.page
        return hostingController
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
}
