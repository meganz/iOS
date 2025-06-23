import MEGASDKRepo

extension DependencyInjection {
    static func composeSDKRepo() {
        MEGASDKRepo.DependencyInjection.sharedSdk = .sharedSdk
    }
}
