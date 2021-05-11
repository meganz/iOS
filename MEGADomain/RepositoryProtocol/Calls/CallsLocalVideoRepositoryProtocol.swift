
protocol CallsLocalVideoRepositoryProtocol {
    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func addLocalVideo(for chatId: MEGAHandle, localVideoListener: CallsLocalVideoListenerRepositoryProtocol)
    func removeLocalVideo(for chatId: MEGAHandle, localVideoListener: CallsLocalVideoListenerRepositoryProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String)
}

protocol CallsLocalVideoListenerRepositoryProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data!)
    func localVideoChangedCameraPosition()
}
