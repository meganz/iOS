@testable import MEGA

class MockCallLocalVideoUseCase: CallLocalVideoUseCaseProtocol {
    var enableDisableVideoCompletion: Result<Void, CallErrorEntity> = .success(())
    var releaseDeviceResult: Result<Void, CallErrorEntity> = .success(())
    var selectCameraResult: Result<Void, CameraSelectionErrorEntity> = .success(())
    var videoDeviceSelectedString: String?
    var addLocalVideo_CalledTimes = 0
    var removeLocalVideo_CalledTimes = 0
    var selectedCamera_calledTimes = 0
    var openDevice_calledTimes = 0
    var releaseVideoDevice_calledTimes = 0

    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        completion(enableDisableVideoCompletion)
    }
    
    func addLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallLocalVideoCallbacksUseCaseProtocol) {
        addLocalVideo_CalledTimes += 1
    }
    
    func removeLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallLocalVideoCallbacksUseCaseProtocol) {
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
