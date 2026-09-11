import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import MEGASdk

enum MediaTabTimelineFactory {
    @MainActor
    static func makeMediaTimelineTabContentViewModel(
        navigationController: UINavigationController?
    ) -> MediaTimelineTabContentViewModel {
        let configuration = PhotoLibraryContentConfiguration()
        let photoLibraryContentViewModel = PhotoLibraryContentViewModel(
            library: PhotoLibrary(),
            contentMode: .library,
            configuration: configuration)
        let photoLibraryContentViewRouter = PhotoLibraryContentViewRouter(
            contentMode: .library)
        let cameraUploadsSettingsViewRouter = CameraUploadsSettingsViewRouter(presenter: navigationController) { }
        
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(
            repo: UserAttributeRepository.newRepo)
        
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))

        let sensitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase)
        
        let photoLibraryUseCase =  PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase
        )
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        
        // Read once, only to inherit a direction chosen before the timeline kept its own order.
        let sortOrderPreferenceUseCase = SortOrderPreferenceUseCase(
            preferenceUseCase: PreferenceUseCase.default,
            sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
        )

        let monitorCameraUploadUseCase = MonitorCameraUploadUseCase(
            cameraUploadRepository: CameraUploadsStatsRepository.newRepo,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default
        )
        
        // The `imtp` remote flag is read here, at the composition root, and nowhere else:
        // when on we inject the use case, whose presence switches the view model to the
        // skeleton path. Off = the use case is nil = unchanged eager path.
        let mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? =
            DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaTimelinePagination)
            ? MediaTimelineUseCase(
                repository: MediaTimelineRepository(
                    sdk: .shared,
                    cameraUploadNodeAccess: CameraUploadNodeAccess.shared,
                    mediaUploadNodeAccess: MediaUploadNodeAccess.shared,
                    nodeUpdatesProvider: NodeUpdatesProvider()),
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase)
            : nil

        // Read here, at the composition root, like the pagination flag above. It alone decides
        // whether the timeline offers a capture-time order: both paths honour one, the paginated
        // by having the SDK order and bucket by it, the eager by grouping its loaded nodes by it.
        let isDateTakenSortEnabled = DIContainer.remoteFeatureFlagUseCase
            .isFeatureFlagEnabled(for: .iosMediaTimelineDateTaken)

        let timelineViewModel = NewTimelineViewModel(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            mediaTimelineUseCase: mediaTimelineUseCase,
            isDateTakenSortEnabled: isDateTakenSortEnabled)
        
        return MediaTimelineTabContentViewModel(
            timelineViewModel: timelineViewModel,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase)
    }
}
