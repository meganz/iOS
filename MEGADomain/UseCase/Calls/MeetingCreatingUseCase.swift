// MARK: - Use case protocol -
protocol MeetingCreatingUseCaseProtocol {
    func setChatVideoInDevices(type: MeetingCameraType)
    func openVideoDevice()
    func releaseDevice()
    func videoDevices() -> [String]
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate)

    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<MEGARequest, MEGASDKErrorType>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct MeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {

    private let repository: MeetingCreatingRepositoryProtocol
    
    init(repository: MeetingCreatingRepositoryProtocol) {
        self.repository = repository
    }
    
    func setChatVideoInDevices(type: MeetingCameraType) {
        let devices = videoDevices()
        switch type {
        case .front:
            repository.setChatVideoInDevices(device: devices[1])
        case .back:
            repository.setChatVideoInDevices(device: devices[0])
        }
    }
    
    func openVideoDevice() {
        repository.openVideoDevice()
    }
    
    func releaseDevice() {
        repository.releaseDevice()
    }
    
    func videoDevices() -> [String] {
        repository.videoDevices()
    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.startChatCall(meetingName: meetingName, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.joinChatCall(forChatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func getUsername() -> String {
        repository.getUsername()
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        repository.getCall(forChatId: chatId)
    }
    
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
        repository.addChatLocalVideo(delegate: delegate)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.checkChatLink(link: link, completion: completion)
    }

    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<MEGARequest, MEGASDKErrorType>) -> Void) {
        repository.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link, completion: completion)
    }
    
}
