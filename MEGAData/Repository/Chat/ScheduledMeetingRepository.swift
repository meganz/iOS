import ChatRepo
import Combine
import MEGADomain
import MEGASwift

public final class ScheduledMeetingRepository: ScheduledMeetingRepositoryProtocol {
    public static var newRepo: ScheduledMeetingRepository {
        ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)
    }
    
    private let chatSDK: MEGAChatSdk
    private var ocurrencesUpdateRequestListener: OcurrencesUpdateRequestListener?

    public init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
    }
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        chatSDK
            .getAllScheduledMeetings()
            .compactMap { scheduledMeeting in
                guard !scheduledMeeting.isCancelled,
                      let chatRoom = chatSDK.chatRoom(forChatId: scheduledMeeting.chatId),
                      !chatRoom.isArchived, chatRoom.ownPrivilege.toOwnPrivilegeEntity().isUserInChat else {
                    return nil
                }
                return scheduledMeeting.toScheduledMeetingEntity()
            }
    }
    
    public func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        chatSDK
            .scheduledMeetings(byChat: chatId)
            .compactMap {
                $0.toScheduledMeetingEntity()
            }
    }
    
    public func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity? {
        chatSDK.scheduledMeeting(chatId, scheduledId: scheduledMeetingId).toScheduledMeetingEntity()
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            chatSDK
                .fetchScheduledMeetingOccurrences(byChat: chatId, delegate: ChatRequestDelegate { result in
                    guard Task.isCancelled == false else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    if case .success(let request) = result {
                        let occurrences = request.chatScheduledMeetingOccurrences.map { $0.toScheduledMeetingOccurrenceEntity() }
                        continuation.resume(returning: occurrences)
                    } else {
                        continuation.resume(throwing: ChatRoomErrorEntity.noChatRoomFound)
                    }
                })
        }
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [ScheduledMeetingOccurrenceEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            chatSDK
                .fetchScheduledMeetingOccurrences(byChat: chatId, since: UInt64(since.timeIntervalSince1970), delegate: ChatRequestDelegate { result in
                    guard Task.isCancelled == false else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    if case .success(let request) = result {
                        let occurrences = request.chatScheduledMeetingOccurrences.map { $0.toScheduledMeetingOccurrenceEntity() }
                        continuation.resume(returning: occurrences)
                    } else {
                        continuation.resume(throwing: ChatRoomErrorEntity.noChatRoomFound)
                    }
                })
        }
    }
    
    public func createScheduleMeeting(_ meeting: ScheduleMeetingProxyEntity) async throws -> ScheduledMeetingEntity {
        let peerlist = MEGAChatPeerList()
        meeting.participantHandleList.forEach { peerlist.addPeer(withHandle: $0, privilege: 2)}
        
        return try await withAsyncThrowingValue { completion in
            chatSDK.createChatroomAndSchedMeeting(
                withPeers: peerlist,
                isMeeting: true,
                isPublicChat: true,
                title: meeting.title,
                speakRequest: false,
                waitingRoom: meeting.waitingRoom,
                openInvite: meeting.allowNonHostsToAddParticipantsEnabled,
                timezone: TimeZone.current.identifier,
                startDate: Int(meeting.startDate.timeIntervalSince1970),
                endDate: Int(meeting.endDate.timeIntervalSince1970),
                description: meeting.description,
                flags: MEGAChatScheduledFlags(sendEmails: meeting.calendarInvite),
                rules: meeting.rules?.frequency != .invalid ? meeting.rules?.toMEGAChatScheduledRules() : nil,
                attributes: nil,
                delegate: makeChatRequestDelegate(withCompletion: completion)
            )
        }
    }
    
    public func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity) async throws -> ScheduledMeetingEntity {
        try await withAsyncThrowingValue { completion in
            chatSDK.updateScheduledMeeting(
                meeting.chatId,
                scheduledId: meeting.scheduledId,
                timezone: TimeZone.current.identifier,
                startDate: UInt64(meeting.startDate.timeIntervalSince1970),
                endDate: UInt64(meeting.endDate.timeIntervalSince1970),
                title: meeting.title,
                description: meeting.description,
                cancelled: meeting.cancelled,
                flags: meeting.flags.toMEGAChatScheduledFlags(),
                rules: meeting.rules.frequency != .invalid ? meeting.rules.toMEGAChatScheduledRules() : nil,
                delegate: makeChatRequestDelegate(withCompletion: completion)
            )
        }
    }
    
    public func updateOccurrence(
        _ occurrence: ScheduledMeetingOccurrenceEntity,
        meeting: ScheduledMeetingEntity
    ) async throws -> ScheduledMeetingEntity {
        try await withAsyncThrowingValue { completion in
            chatSDK.updateScheduledMeetingOccurrence(
                meeting.chatId,
                scheduledId: occurrence.scheduledId,
                overrides: occurrence.overrides,
                newStartDate: UInt64(occurrence.startDate.timeIntervalSince1970),
                newEndDate: UInt64(occurrence.endDate.timeIntervalSince1970),
                newCancelled: occurrence.cancelled,
                delegate: makeChatRequestDelegate(withCompletion: completion)
            )
        }
    }
    
    public func ocurrencesShouldBeReloadListener(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        let ocurrencesUpdateRequestListener = OcurrencesUpdateRequestListener(sdk: chatSDK, chatId: chatRoom.chatId)
        self.ocurrencesUpdateRequestListener = ocurrencesUpdateRequestListener
        return ocurrencesUpdateRequestListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private methods
    
    private func makeChatRequestDelegate(withCompletion completion: @escaping (Result<ScheduledMeetingEntity, any Error>) -> Void) -> ChatRequestDelegate {
        ChatRequestDelegate { result in
            if case .success(let request) = result {
                guard let scheduledMeeting = request.scheduledMeetingList.first?.toScheduledMeetingEntity() else {
                    completion(.failure(ScheduleMeetingErrorEntity.scheduledMeetingNotFound))
                    return
                }
                
                completion(.success(scheduledMeeting))
            } else if case .failure(let error) = result {
                completion(.failure(error))
            } else {
                completion(.failure(GenericErrorEntity()))
            }
        }
    }
}

private final class OcurrencesUpdateRequestListener: NSObject, MEGAChatScheduledMeetingDelegate {
    private let sdk: MEGAChatSdk
    private let chatId: ChatIdEntity
    private let source = PassthroughSubject<Bool, Never>()

    var monitor: AnyPublisher<Bool, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, chatId: ChatIdEntity) {
        self.sdk = sdk
        self.chatId = chatId
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onSchedMeetingOccurrencesUpdate(_ api: MEGAChatSdk, chatId: UInt64, append: Bool) {
        if chatId == self.chatId {
            source.send(!append)
        }
    }
}
