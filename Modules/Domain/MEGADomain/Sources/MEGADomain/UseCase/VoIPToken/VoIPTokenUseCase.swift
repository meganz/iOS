public protocol VoIPTokenUseCaseProtocol {
    func registerVoIPDeviceToken(_ token: String)
}
public struct VoIPTokenUseCase<T: VoIPTokenRepositoryProtocol>: VoIPTokenUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }

    public func registerVoIPDeviceToken(_ token: String) {
        repo.registerVoIPDeviceToken(token)
    }
}
