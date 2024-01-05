@testable import MEGA
import MEGADomain

final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    let userName: String
    var createMeetingResult: Result<ChatRoomEntity, CallErrorEntity>
    var createEphemeralAccountCompletion: Result<Void, GenericErrorEntity>
    var joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity>
    var checkChatLinkCompletion: Result<ChatRoomEntity, CallErrorEntity>
    
    var createChatLink_calledTimes = 0
    
    init(userName: String = "Test Name",
         createMeetingResult: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
         createEphemeralAccountCompletion: Result<Void, GenericErrorEntity> = .failure(GenericErrorEntity()),
         joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
         checkChatLinkCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic)
    ) {
        self.userName = userName
        self.createMeetingResult = createMeetingResult
        self.createEphemeralAccountCompletion = createEphemeralAccountCompletion
        self.joinCallCompletion = joinCallCompletion
        self.checkChatLinkCompletion = checkChatLinkCompletion
    }
    
    func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity {
        switch createMeetingResult {
        case .success(let chatRoom):
            return chatRoom
        case .failure(let error):
            throw error
        }
    }
    
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(joinCallCompletion)
    }
    
    func username() -> String {
        userName
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(checkChatLinkCompletion)
    }
    
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void) {
        completion(createEphemeralAccountCompletion)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        createChatLink_calledTimes += 1
    }
}
