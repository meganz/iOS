@testable import MEGA

final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    var chatCallCompletion: Result<ChatRoomEntity, CallsErrorEntity>?
    var requestCompletion: Result<MEGARequest, MEGASDKErrorType>?
    var createEpehemeralAccountCompletion: Result<Void, MEGASDKErrorType>?
    var joinCallCompletion: Result<ChatRoomEntity, CallsErrorEntity> = .failure(.generic)

    var createChatLink_calledTimes = 0
    var addChatLocalVideo_CalledTimes = 0
    
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        if let completionBlock = chatCallCompletion {
            completion(completionBlock)
        }
    }
    
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        if let completionBlock = chatCallCompletion {
            completion(completionBlock)
        }
    }
    
    func getUsername() -> String {
        "test name"
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
    }
    
    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
        addChatLocalVideo_CalledTimes += 1
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<MEGARequest, MEGASDKErrorType>) -> Void) {
        if let completionBlock = requestCompletion {
            completion(completionBlock)
        }
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        if let completionBlock = chatCallCompletion {
            completion(completionBlock)
        }
    }
 
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        if let completionBlock = createEpehemeralAccountCompletion {
            completion(completionBlock)
        }
    }
    
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        completion(joinCallCompletion)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        createChatLink_calledTimes += 1
    }
}
