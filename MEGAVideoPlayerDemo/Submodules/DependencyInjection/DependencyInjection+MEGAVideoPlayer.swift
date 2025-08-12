import MEGAVideoPlayer

extension DependencyInjection {
    static func composeVideoPlayer() {
        MEGAVideoPlayer.DependencyInjection.sharedSdk = .sharedSdk
    }
}
