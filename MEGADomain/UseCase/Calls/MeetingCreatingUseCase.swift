// MARK: - Use case protocol -
protocol MeetingCreatingUseCaseProtocol {
    func setChatVideoInDevices(type: MeetingCameraType)
    func openVideoDevice()
    func releaseDevice()
    func videoDevices() -> [String]
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void)
    func getUsername() -> String
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate)

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
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void) {
        repository.startChatCall(meetingName: meetingName, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func getUsername() -> String {
        repository.getUsername()
    }
    
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
        repository.addChatLocalVideo(delegate: delegate)
    }
}
