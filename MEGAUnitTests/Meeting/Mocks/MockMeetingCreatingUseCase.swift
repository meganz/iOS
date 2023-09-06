@testable import MEGA
import MEGADomain

final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    let userName: String
    var chatCallCompletion: Result<ChatRoomEntity, CallErrorEntity>
    var createEpehemeralAccountCompletion: Result<Void, MEGASDKErrorType>
    var joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity>
    var joinChatCompletion: Result<ChatRoomEntity, CallErrorEntity>
    
    var createChatLink_calledTimes = 0
    
    init(userName: String = "Test Name",
         chatCallCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
         createEpehemeralAccountCompletion: Result<Void, MEGASDKErrorType> = .failure(.unexpected),
         joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
         joinChatCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic)) {
        self.userName = userName
        self.chatCallCompletion = chatCallCompletion
        self.createEpehemeralAccountCompletion = createEpehemeralAccountCompletion
        self.joinCallCompletion = joinCallCompletion
        self.joinChatCompletion = joinChatCompletion
    }
    
    func startCall(_ startCall: StartCallEntity, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(chatCallCompletion)
    }
    
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(joinCallCompletion)
    }
    
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<MEGADomain.ChatRoomEntity, MEGADomain.CallErrorEntity>) -> Void) {
        completion(joinChatCompletion)
    }
    
    func getUsername() -> String {
        userName
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        CallEntity(status: .inProgress, chatId: 0, callId: 0, changeType: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], waitingRoomStatus: .unknown, waitingRoom: nil, waitingRoomHandleList: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(chatCallCompletion)
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        completion(createEpehemeralAccountCompletion)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        createChatLink_calledTimes += 1
    }
}
