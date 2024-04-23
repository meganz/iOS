import MEGADomain

public final class MockVoIPTokenUseCase: VoIPTokenUseCaseProtocol {
    public var registerVoIPDeviceToken_CalledTimes = 0

    public init() {}
    
    public func registerVoIPDeviceToken(_ token: String) {
        registerVoIPDeviceToken_CalledTimes += 1
    }
}
