enum DependencyInjection {
    static func compose() {
        composeSDKRepo()
        composeInfrastructure()
        composeLogger()
        composeAuthentication()
        composeAccountManagement()
    }

    // MARK: - Private

    static var fetchVideoNodesUseCase: some FetchVideoNodesUseCaseProtocol {
        FetchVideoNodesUseCase(
            sdk: .sharedSdk,
            nodesUpdatesStream: nodesUpdatesStream
        )
    }

    static var streamingUseCase: some StreamingUseCaseProtocol {
        StreamingUseCase(repository: StreamingRepository(sdk: .sharedSdk))
    }

    static var selectVideoPlayerOptionUseCase: some SelectVideoPlayerUseCaseProtocol {
        SelectVideoPlayerUseCase.shared
    }
}
