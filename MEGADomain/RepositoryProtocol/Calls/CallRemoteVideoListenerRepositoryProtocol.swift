import MEGADomain

protocol CallRemoteVideoRepositoryProtocol {
    func enableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool, remoteVideoListener: some CallRemoteVideoListenerRepositoryProtocol)
    func disableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
}

protocol CallRemoteVideoListenerRepositoryProtocol {
    func remoteVideoFrameData(clientId: HandleEntity, width: Int, height: Int, buffer: Data)
}
