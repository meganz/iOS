@testable import MEGA

final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    var chatCallCompletion: Result<ChatRoomEntity, CallErrorEntity>?
    var requestCompletion: Result<MEGARequest, MEGASDKErrorType>?
    var createEpehemeralAccountCompletion: Result<Void, MEGASDKErrorType>?
    var joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic)

    var createChatLink_calledTimes = 0
    
    func startCall(meetingName: String, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        if let completionBlock = chatCallCompletion {
            completion(completionBlock)
        }
    }
    
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(joinCallCompletion)
    }
    
    func getUsername() -> String {
        "test name"
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        if let completionBlock = chatCallCompletion {
            completion(completionBlock)
        }
    }
 
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        if let completionBlock = createEpehemeralAccountCompletion {
            completion(completionBlock)
        }
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        createChatLink_calledTimes += 1
    }
}
