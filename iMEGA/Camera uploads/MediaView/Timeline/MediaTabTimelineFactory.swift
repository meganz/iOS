import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

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
        
        let sensitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
        
        let photoLibraryUseCase =  PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        
        let monitorCameraUploadUseCase = MonitorCameraUploadUseCase(
            cameraUploadRepository: CameraUploadsStatsRepository.newRepo,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default
        )
        
        let timelineViewModel = NewTimelineViewModel(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase)
        
        return MediaTimelineTabContentViewModel(
            timelineViewModel: timelineViewModel,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase)
    }
}
