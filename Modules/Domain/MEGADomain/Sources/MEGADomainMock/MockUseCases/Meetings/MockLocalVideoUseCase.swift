import MEGADomain

public final class MockCallLocalVideoUseCase: CallLocalVideoUseCaseProtocol, @unchecked Sendable {
    public var enableDisableVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    private let releaseDeviceResult: Result<Void, CallErrorEntity> = .failure(.generic)
    public var videoDeviceSelectedString: String?
    public var enableLocalVideo_CalledTimes = 0
    public var disableLocalVideo_CalledTimes = 0
    var addLocalVideo_CalledTimes = 0
    var removeLocalVideo_CalledTimes = 0
    public var selectedCameras = [String]()
    var openDevice_calledTimes = 0
    var releaseVideoDevice_calledTimes = 0

    public init() {}
    
    public func enableLocalVideo(for chatId: HandleEntity) async throws {
        enableLocalVideo_CalledTimes += 1
    }
    
    public func disableLocalVideo(for chatId: HandleEntity) async throws {
        disableLocalVideo_CalledTimes += 1
    }
    
    public func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    public func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    public func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        addLocalVideo_CalledTimes += 1
    }
    
    public func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        removeLocalVideo_CalledTimes += 1
    }
    
    public func videoDeviceSelected() -> String? {
        return videoDeviceSelectedString
    }
    
    public func selectCamera(withLocalizedName localizedName: String) {
        selectedCameras.append(localizedName)
    }
    
    public func selectCamera(withLocalizedName localizedName: String) async throws {
        selectedCameras.append(localizedName)
    }

    public func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        openDevice_calledTimes += 1
    }
    
    public func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        releaseVideoDevice_calledTimes += 1
        completion(releaseDeviceResult)
    }
}
