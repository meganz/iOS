protocol MeetingCreatingRepositoryProtocol {
    func setChatVideoInDevices(device: String)
    func openVideoDevice()
    func releaseDevice()
    func videoDevices() -> [String]
    func getUsername() -> String
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void)
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate)
}
