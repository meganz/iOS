@testable import MEGA

class MockCallLocalVideoUseCase: CallLocalVideoUseCaseProtocol {
    var enableDisableVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    var releaseDeviceResult: Result<Void, CallErrorEntity> = .failure(.generic)
    var selectCameraResult: Result<Void, CameraSelectionErrorEntity> = .failure(.generic)
    var videoDeviceSelectedString: String?
    var addLocalVideo_CalledTimes = 0
    var removeLocalVideo_CalledTimes = 0
    var selectedCamera_calledTimes = 0
    var openDevice_calledTimes = 0
    var releaseVideoDevice_calledTimes = 0

    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: CallLocalVideoCallbacksUseCaseProtocol) {
        addLocalVideo_CalledTimes += 1
    }
    
    func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: CallLocalVideoCallbacksUseCaseProtocol) {
        removeLocalVideo_CalledTimes += 1
    }
    
    func videoDeviceSelected() -> String? {
        return videoDeviceSelectedString
    }
    
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionErrorEntity>) -> Void) {
        selectedCamera_calledTimes += 1
        completion(selectCameraResult)
    }
    
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        openDevice_calledTimes += 1
    }
    
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        releaseVideoDevice_calledTimes += 1
        completion(releaseDeviceResult)
    }
}
