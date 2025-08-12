enum DependencyInjection {
    static func compose() {
        composeSDKRepo()
        composeLogger()
        composeAuthentication()
        composeAccountManagement()
        composeVideoPlayer()
    }

    // MARK: - Private

    static var fetchVideoNodesUseCase: some FetchVideoNodesUseCaseProtocol {
        FetchVideoNodesUseCase(
            sdk: .sharedSdk,
            nodesUpdatesStream: nodesUpdatesStream
        )
    }
}
