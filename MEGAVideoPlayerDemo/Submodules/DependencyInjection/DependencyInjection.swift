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
        FetchVideoNodesUseCase(sdk: .sharedSdk)
    }
}
