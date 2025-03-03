import ContentLibraries
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
    
    init(navigationController: UINavigationController?, album: AlbumEntity, newAlbumPhotos: [NodeEntity]?) {
        self.navigationController = navigationController
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
    }
    
    func build() -> UIViewController {
        let albumContentsUpdateRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let filesSearchRepo = FilesSearchRepository.newRepo
        let userAlbumRepo = UserAlbumRepository.newRepo
        let sensitiveDisplayPreferenceUseCase = makeSensitiveDisplayPreferenceUseCase()
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsUpdateRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: filesSearchRepo),
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: userAlbumRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo))
        )
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )

        let viewModel = AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            albumModificationUseCase: AlbumModificationUseCase(
                userAlbumRepo: userAlbumRepo),
            photoLibraryUseCase: photoLibraryUseCase,
            shareCollectionUseCase: ShareCollectionUseCase(
                shareAlbumRepository: ShareCollectionRepository.newRepo,
                userAlbumRepository: UserAlbumRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            monitorAlbumPhotosUseCase: makeMonitorAlbumPhotosUseCase(),
            albumNameUseCase: AlbumNameUseCase(
                userAlbumRepository: userAlbumRepo),
            router: self,
            newAlbumPhotosToAdd: newAlbumPhotos)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )
        let fileSearchRepository = FilesSearchRepository.newRepo
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepository,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )

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
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo))
        )
        
        let viewModel = AlbumCoverPickerViewModel(album: album,
                                                  albumContentsUseCase: albumContentsUseCase, router: self,
                                                  completion: completion)
        let content = AlbumCoverPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(rootView: content),
                                      animated: true)
    }
    
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell {
        let nodeRepository = NodeRepository.newRepo
        let vm = AlbumCoverPickerPhotoCellViewModel(
            albumPhoto: albumPhoto,
            photoSelection: photoSelection,
            viewModel: PhotoLibraryModeAllViewModel(libraryViewModel: PhotoLibraryContentViewModel(library: PhotoLibrary())),
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: nodeRepository),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: nodeRepository,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo))
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
        PhotoLibraryUseCase(
            photosRepository: PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared),
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
    }
    
    private func makeMonitorAlbumPhotosUseCase() -> some MonitorAlbumPhotosUseCaseProtocol {
        let sensitiveNodeUseCase =  SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
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
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo,
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
        )
    }
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
}
