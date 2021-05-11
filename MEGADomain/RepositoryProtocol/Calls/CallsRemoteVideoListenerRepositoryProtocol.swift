
protocol CallsRemoteVideoRepositoryProtocol {
    func enableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool, remoteVideoListener: CallsRemoteVideoListenerRepositoryProtocol)
    func disableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
}

protocol CallsRemoteVideoListenerRepositoryProtocol {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data!)
}
