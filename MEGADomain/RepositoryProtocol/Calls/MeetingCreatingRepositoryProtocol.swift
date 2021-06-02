protocol MeetingCreatingRepositoryProtocol {
    func setChatVideoInDevices(device: String)
    func openVideoDevice()
    func releaseDevice()
    func videoDevices() -> [String]
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate)
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void)

}
