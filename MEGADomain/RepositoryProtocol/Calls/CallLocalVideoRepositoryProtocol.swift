import MEGADomain

protocol CallLocalVideoRepositoryProtocol {
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func addLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol)
    func removeLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionErrorEntity>) -> Void)
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
}

protocol CallLocalVideoListenerRepositoryProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data)
    func localVideoChangedCameraPosition()
}
