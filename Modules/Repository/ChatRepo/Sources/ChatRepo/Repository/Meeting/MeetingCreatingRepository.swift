import Foundation
import MEGAChatSdk
import MEGADomain
import MEGASDKRepo
import MEGASwift

public final class MeetingCreatingRepository: NSObject, MeetingCreatingRepositoryProtocol, Sendable {
    
    public static var newRepo: MeetingCreatingRepository {
        MeetingCreatingRepository(
            chatSdk: .sharedChatSdk,
            sdk: .sharedSdk,
            chatConnectionStateUpdateProvider: ChatUpdatesProvider(sdk: .sharedChatSdk)
        )
    }
    
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk
    private let chatConnectionStateUpdateProvider: any ChatUpdatesProviderProtocol
    
    public init(
        chatSdk: MEGAChatSdk,
        sdk: MEGASdk,
        chatConnectionStateUpdateProvider: some ChatUpdatesProviderProtocol
    ) {
        self.chatSdk = chatSdk
        self.sdk = sdk
        self.chatConnectionStateUpdateProvider = chatConnectionStateUpdateProvider
    }
    
    public var username: String {
        chatSdk.userFullnameFromCache(byUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? 0) ?? ""
    }
    
    public var userEmail: String? {
        sdk.myEmail
    }
    
    public func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity {
        try await withAsyncThrowingValue { result in
            let delegate = ChatRequestDelegate { [weak self] completion in
                switch completion {
                case .success(let request):
                    guard let self, let megaChatRoom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                        result(.failure(CallErrorEntity.generic))
                        return
                    }
                    let chatRoom = megaChatRoom.toChatRoomEntity()
                    result(.success(chatRoom))
                case .failure:
                    result(.failure(CallErrorEntity.generic))
                }
            }
            chatSdk.createMeeting(
                withTitle: startCall.meetingName,
                speakRequest: startCall.speakRequest,
                waitingRoom: startCall.waitingRoom,
                openInvite: startCall.allowNonHostToAddParticipants,
                queueType: .main,
                delegate: delegate
            )
        }
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        try await withAsyncThrowingValue { continuation in
            let delegate = ChatRequestDelegate { [weak self] result in
                switch result {
                case .success(let request):
                    guard let self,
                            let megaChatRoom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                        continuation(.failure(GenericErrorEntity()))
                        return
                    }
                    
                    let chatRoom = megaChatRoom.toChatRoomEntity()
                    continuation(.success(chatRoom))
                case .failure:
                    continuation(.failure(GenericErrorEntity()))
                }
            }
            
            if let megaChatRoom = chatSdk.chatRoom(forChatId: chatId),
               !megaChatRoom.isPreview,
               !megaChatRoom.isActive {
                chatSdk.autorejoinPublicChat(chatId, publicHandle: userHandle, delegate: delegate)
            } else {
                chatSdk.autojoinPublicChat(chatId, delegate: delegate)
            }
        }
    }
    
    public func checkChatLink(link: String) async throws -> ChatRoomEntity {
        try await withAsyncThrowingValue { continuation in
            guard let url = URL(string: link) else {
                continuation(.failure(GenericErrorEntity()))
                return
            }
            
            chatSdk.checkChatLink(url, delegate: ChatRequestDelegate { [weak self] result in
                guard let self else {
                    continuation(.failure(GenericErrorEntity()))
                    return
                }
                switch result {
                case .success(let request):
                    guard let chatroom = chatSdk.chatRoom(forChatId: request.chatHandle) else {
                        continuation(.failure(GenericErrorEntity()))
                        return
                    }
                    
                    continuation(.success(chatroom.toChatRoomEntity()))
                case .failure:
                    continuation(.failure(GenericErrorEntity()))
                }
            })
        }
    }
    
    public func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        karereInitCompletion: (() -> Void)? = nil
    ) async throws {
        do {
            try await logoutFromChat()
            chatSdk.initKarere(withSid: nil)
            if let karereInitCompletion {
                karereInitCompletion()
            }
            
            let request = try await createEphemeralAccount(firstName: firstName, lastName: lastName)
            
            if request.paramType == AccountActionType.resumeEphemeralPlusPlus.rawValue {
                try Task.checkCancellation()
                try await fetchNodes()
            }
            
            try Task.checkCancellation()
            try await connectToChat(link: link)
            
        } catch {
            throw GenericErrorEntity()
        }
    }
    
    // MARK: - Private

    private func logoutFromChat() async throws {
        try await withCheckedThrowingContinuation { continuation in
            chatSdk.logout(with: ChatRequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure:
                    continuation.resume(throwing: GenericErrorEntity())
                }
            })
        }
    }

    private func createEphemeralAccount(firstName: String, lastName: String) async throws -> MEGARequest {
        try await withCheckedThrowingContinuation { continuation in
            sdk.createEphemeralAccountPlusPlus(withFirstname: firstName, lastname: lastName, delegate: RequestDelegate { result in
                switch result {
                case .failure:
                    continuation.resume(throwing: GenericErrorEntity())
                case .success(let request):
                    continuation.resume(returning: request)
                }
            })
        }
    }

    private func fetchNodes() async throws {
        try await withAsyncThrowingValue { completion in
            sdk.fetchNodes(with: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }

    private func connectToChat(link: String) async throws {
        guard let url = URL(string: link) else {
            throw GenericErrorEntity()
        }

        let chatRequest = try await openChatPreview(url: url)
        try await handleChatConnection(chatRequest: chatRequest)
    }

    private func openChatPreview(url: URL) async throws -> MEGAChatRequest {
        try await withAsyncThrowingValue { completion in
            chatSdk.openChatPreview(url, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let chatRequest):
                    completion(.success(chatRequest))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }

    private func handleChatConnection(chatRequest: MEGAChatRequest) async throws {
        let chatHandle = chatRequest.chatHandle
        _ = await chatConnectionStateUpdateProvider
            .updates
            .first { $0 == chatHandle && $1 == .online }

        try Task.checkCancellation()
    }
}
