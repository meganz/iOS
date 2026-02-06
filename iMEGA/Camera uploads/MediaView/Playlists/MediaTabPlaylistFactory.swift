import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASdk
import MEGASwiftUI
import Video

struct MediaTabPlaylistFactory {
    @MainActor static func makePlaylistTabViewModel(
        syncModel: VideoRevampSyncModel,
        navigationController: UINavigationController?,
        hiddenNodesFeatureFlagEnabled: Bool
    ) -> PlaylistTabViewModel {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository.newRepo

        // FilesSearchUseCase
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )

        // PhotoLibraryUseCase setup
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )

        let sensitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: nodeRepository,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            ),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo
            ),
            hiddenNodesFeatureFlagEnabled: {
                hiddenNodesFeatureFlagEnabled
            }
        )

        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )

        // Video playlist related use cases
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase
        )

        // SensitiveNodeUseCase for VideoPlaylistContentsUseCase
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )

        let videoPlaylistContentUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )

        let videoPlaylistModificationUseCase = VideoPlaylistModificationUseCase(
            userVideoPlaylistsRepository: userVideoPlaylistsRepo
        )

        let sortOrderPreferenceUseCase = SortOrderPreferenceUseCase(
            preferenceUseCase: PreferenceUseCase.default,
            sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
        )

        let accountStorageUseCase = AccountStorageUseCase(
            accountRepository: AccountRepository.newRepo,
            preferenceUseCase: PreferenceUseCase.default
        )

        let thumbnailLoader = VideoRevampFactory.makeThumbnailLoader(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared)
        )

        let router = VideoRevampRouter(
            explorerType: .video,
            navigationController: navigationController,
            syncModel: syncModel
        )

        let videoPlaylistsViewModel = VideoPlaylistsViewModel(
            videoPlaylistsUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            accountStorageUseCase: accountStorageUseCase,
            syncModel: syncModel,
            alertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: nil
            ),
            renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Title.rename,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.rename,
                affirmativeButtonInitiallyEnabled: false,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Subtitle.enterTheNewName
            ),
            thumbnailLoader: thumbnailLoader,
            featureFlagProvider: DIContainer.featureFlagProvider,
            contentProvider: VideoPlaylistsViewModelContentProvider(
                videoPlaylistsUseCase: videoPlaylistUseCase
            ),
            videoRevampRouter: router
        )

        return PlaylistTabViewModel(
            videoPlaylistsViewModel: videoPlaylistsViewModel,
            videoConfig: .live(),
            router: router
        )
    }
}
