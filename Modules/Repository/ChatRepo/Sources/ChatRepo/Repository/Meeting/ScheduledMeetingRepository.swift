@preconcurrency import Combine
import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class ScheduledMeetingRepository: ScheduledMeetingRepositoryProtocol {
    public static var newRepo: ScheduledMeetingRepository {
        ScheduledMeetingRepository(chatSDK: MEGAChatSdk.sharedChatSdk)
    }
    
    private let chatSDK: MEGAChatSdk
    private let occurrencesUpdateRequestListener: OccurrencesUpdateRequestListener

    public init(chatSDK: MEGAChatSdk) {
        self.chatSDK = chatSDK
        occurrencesUpdateRequestListener = OccurrencesUpdateRequestListener(sdk: chatSDK)
    }
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        chatSDK
            .getAllScheduledMeetings()?
            .compactMap { (scheduledMeeting: MEGAChatScheduledMeeting) -> ScheduledMeetingEntity? in
                guard
                    !scheduledMeeting.isCancelled,
                    let chatRoom = chatSDK.chatRoom(forChatId: scheduledMeeting.chatId),
                    !chatRoom.isArchived, chatRoom.ownPrivilege.toChatRoomPrivilegeEntity().isUserInChat
                else {
                    return nil
                }
                
                return scheduledMeeting.toScheduledMeetingEntity()
            } ?? []
    }
    
    public func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        chatSDK
            .scheduledMeetings(byChat: chatId)
            .compactMap {
                $0.toScheduledMeetingEntity()
            }
    }
    
    public func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity? {
        chatSDK.scheduledMeeting(chatId, scheduledId: scheduledMeetingId)?.toScheduledMeetingEntity()
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await fetchScheduledMeetings(chatId: chatId)
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await fetchScheduledMeetings(chatId: chatId, since: since)
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
    
    public func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity, updateChatTitle: Bool) async throws -> ScheduledMeetingEntity {
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
                updateChatTitle: updateChatTitle,
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
    
    public func occurrencesShouldBeReloadListener(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        return occurrencesUpdateRequestListener
            .monitor
            .filter {$0.0 == chatRoom.chatId }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private methods
    
    private func makeChatRequestDelegate(withCompletion completion: @escaping (Result<ScheduledMeetingEntity, any Error>) -> Void) -> ChatRequestDelegate {
        ChatRequestDelegate { result in
            if case .success(let request) = result {
                guard let scheduledMeeting = request.scheduledMeetingList?.first?.toScheduledMeetingEntity() else {
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

    private func fetchScheduledMeetings(chatId: ChatIdEntity, since: Date? = nil) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await withAsyncThrowingValue { completion in
            let delegate = ChatRequestDelegate { result in
                if case .success(let request) = result {
                    let occurrences = request.chatScheduledMeetingOccurrences.map { $0.toScheduledMeetingOccurrenceEntity() }
                    completion(.success(occurrences))
                } else {
                    completion(.failure(ChatRoomErrorEntity.noChatRoomFound))
                }
            }

            if let since = since {
                return chatSDK.fetchScheduledMeetingOccurrences(byChat: chatId, since: UInt64(since.timeIntervalSince1970), delegate: delegate)
            } else {
                return chatSDK.fetchScheduledMeetingOccurrences(byChat: chatId, delegate: delegate)
            }
        }
    }
}

private final class OccurrencesUpdateRequestListener: NSObject, MEGAChatScheduledMeetingDelegate, Sendable {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<(ChatIdEntity, Bool), Never>()

    var monitor: AnyPublisher<(ChatIdEntity, Bool), Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onSchedMeetingOccurrencesUpdate(_ api: MEGAChatSdk, chatId: UInt64, append: Bool) {
        source.send((chatId, !append))
    }
}
