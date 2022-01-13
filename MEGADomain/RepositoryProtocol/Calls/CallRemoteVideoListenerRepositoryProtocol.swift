
protocol CallRemoteVideoRepositoryProtocol {
    func enableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool, remoteVideoListener: CallRemoteVideoListenerRepositoryProtocol)
    func disableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?)
    func stopHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?)
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?)
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?)
}

protocol CallRemoteVideoListenerRepositoryProtocol {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data)
}
