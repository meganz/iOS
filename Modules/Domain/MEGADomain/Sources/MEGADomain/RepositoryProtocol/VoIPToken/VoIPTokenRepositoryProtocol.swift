public protocol VoIPTokenRepositoryProtocol: RepositoryProtocol {
    func registerVoIPDeviceToken(_ token: String)
}
