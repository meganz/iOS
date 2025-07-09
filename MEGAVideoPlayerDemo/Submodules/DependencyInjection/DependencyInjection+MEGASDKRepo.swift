import MEGASDKRepo

extension DependencyInjection {
    static func composeSDKRepo() {
        MEGASDKRepo.DependencyInjection.sharedSdk = .sharedSdk
    }

    static var nodesUpdatesStream: some NodesUpdatesStreamProtocol {
        MEGAUpdateHandlerManager.shared
    }
}
