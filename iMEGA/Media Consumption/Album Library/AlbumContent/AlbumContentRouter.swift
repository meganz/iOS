import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

@MainActor
protocol AlbumContentRouting: Routing {
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void)
    func showAlbumCoverPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void)
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell
    func showShareLink(album: AlbumEntity)
}

struct AlbumContentRouter: AlbumContentRouting {
    private weak var navigationController: UINavigationController?
    private let album: AlbumEntity
    private let newAlbumPhotos: [NodeEntity]?
    private let existingAlbumNames: () -> [String]
        
    init(navigationController: UINavigationController?, album: AlbumEntity, newAlbumPhotos: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) {
        self.navigationController = navigationController
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
        self.existingAlbumNames = existingAlbumNames
    }
    
    func build() -> UIViewController {
        let albumContentsUpdateRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let filesSearchRepo = FilesSearchRepository.newRepo
        let userAlbumRepo = UserAlbumRepository.newRepo
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsUpdateRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: filesSearchRepo),
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: userAlbumRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                                      searchRepository: FilesSearchRepository.newRepo,
                                                      contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                                                        repo: UserAttributeRepository.newRepo),
                                                      hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
        
        let alertViewModel = TextFieldAlertViewModel(textString: album.name,
                                                     title: Strings.Localizable.rename,
                                                     placeholderText: "",
                                                     affirmativeButtonTitle: Strings.Localizable.rename,
                                                     affirmativeButtonInitiallyEnabled: false,
                                                     destructiveButtonTitle: Strings.Localizable.cancel,
                                                     highlightInitialText: true,
                                                     message: Strings.Localizable.renameNodeMessage,
                                                     validator: AlbumNameValidator(existingAlbumNames: existingAlbumNames).rename)
        
        let viewModel = AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
            photoLibraryUseCase: photoLibraryUseCase,
            shareCollectionUseCase: ShareCollectionUseCase(
                shareAlbumRepository: ShareCollectionRepository.newRepo,
                userAlbumRepository: UserAlbumRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            monitorAlbumPhotosUseCase: makeMonitorAlbumPhotosUseCase(),
            router: self,
            newAlbumPhotosToAdd: newAlbumPhotos,
            alertViewModel: alertViewModel)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )
        let fileSearchRepository = FilesSearchRepository.newRepo
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                                      searchRepository: fileSearchRepository,
                                                      contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                                                      hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
        
        let viewModel = AlbumContentPickerViewModel(album: album,
                                                    photoLibraryUseCase: photoLibraryUseCase,
                                                    completion: completion,
                                                    configuration: PhotoLibraryContentConfiguration(
                                                        selectLimit: 150,
                                                        scaleFactor: UIDevice().iPadDevice ? .five : .three)
                                                    )
        let content = AlbumContentPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(rootView: content),
                                      animated: true)
    }
    
    func showAlbumCoverPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void) {
        let filesSearchRepo = FilesSearchRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: AlbumContentsUpdateNotifierRepository.newRepo,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: UserAlbumRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        
        let viewModel = AlbumCoverPickerViewModel(album: album,
                                                  albumContentsUseCase: albumContentsUseCase, router: self,
                                                    completion: completion)
        let content = AlbumCoverPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(rootView: content),
                                      animated: true)
    }
    
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell {
        
        let vm = AlbumCoverPickerPhotoCellViewModel(
            albumPhoto: albumPhoto,
            photoSelection: photoSelection,
            viewModel: PhotoLibraryModeAllViewModel(libraryViewModel: PhotoLibraryContentViewModel(library: PhotoLibrary())),
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo)
        )
        
        return AlbumCoverPickerPhotoCell(viewModel: vm)
    }
    
    func showShareLink(album: AlbumEntity) {
        let viewModel = EnforceCopyrightWarningViewModel(
            preferenceUseCase: PreferenceUseCase.default,
            copyrightUseCase: CopyrightUseCase(
                shareUseCase: ShareUseCase(
                    shareRepository: ShareRepository.newRepo,
                    filesSearchRepository: FilesSearchRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo)))
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            GetAlbumsLinksViewWrapper(albums: [album])
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
        navigationController?.present(UIHostingController(rootView: view),
                                      animated: true)
    }
    
    func start() {}
    
    private func makePhotoLibraryUseCase() -> some PhotoLibraryUseCaseProtocol {
        PhotoLibraryUseCase(photosRepository: PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared),
                            searchRepository: FilesSearchRepository.newRepo,
                            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
    
    private func makeMonitorAlbumPhotosUseCase() -> some MonitorAlbumPhotosUseCaseProtocol {
        let sensitiveNodeUseCase =  SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo)
        let photosRepository = PhotosRepository.sharedRepo
        let monitorPhotosUseCase = MonitorPhotosUseCase(
            photosRepository: photosRepository,
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let monitorSystemAlbumPhotosUseCase = MonitorSystemAlbumPhotosUseCase(
            monitorPhotosUseCase: monitorPhotosUseCase,
            mediaUseCase: MediaUseCase(
                fileSearchRepo: FilesSearchRepository.newRepo)
        )
        let monitorUserAlbumPhotosUseCase = MonitorUserAlbumPhotosUseCase(
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: photosRepository,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        
        return MonitorAlbumPhotosUseCase(
            monitorSystemAlbumPhotosUseCase: monitorSystemAlbumPhotosUseCase,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
    }
}
