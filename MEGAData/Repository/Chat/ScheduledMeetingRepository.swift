import Combine
import MEGAData
import MEGADomain
import MEGASwift

public final class ScheduledMeetingRepository: ScheduledMeetingRepositoryProtocol {
    public static var newRepo: ScheduledMeetingRepository {
        ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)
    }
    
    private let chatSDK: MEGAChatSdk
    
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
    
    public func createScheduleMeeting(_ meeting: CreateScheduleMeetingEntity) async throws -> ScheduledMeetingEntity {
        let peerlist = MEGAChatPeerList()
        meeting.participants.forEach { peerlist.addPeer(withHandle: $0.handle, privilege: 2)}
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            chatSDK.createChatroomAndSchedMeeting(
                withPeers: peerlist,
                isMeeting: true,
                isPublicChat: true,
                title: meeting.title,
                speakRequest: false,
                waitingRoom: false,
                openInvite: meeting.openInvite,
                timezone: TimeZone.current.identifier,
                startDate: Int(meeting.startDate.timeIntervalSince1970),
                endDate: Int(meeting.endDate.timeIntervalSince1970),
                description: meeting.description,
                flags: MEGAChatScheduledFlags(sendEmails: meeting.calendarInvite),
                rules: meeting.rules?.toMEGAChatScheduledRules(),
                attributes: nil,
                delegate: ChatRequestDelegate { result in
                    guard Task.isCancelled == false else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    if case .success(let request) = result {
                        guard let scheduledMeeting = request.scheduledMeetingList.first?.toScheduledMeetingEntity() else {
                            continuation.resume(throwing: ScheduleMeetingErrorEntity.scheduledMeetingNotFound)
                            return
                        }
                        
                        continuation.resume(returning: scheduledMeeting)

                    } else {
                        continuation.resume(throwing: ScheduleMeetingErrorEntity.invalidArguments)
                    }
                }
            )
        }
    }
    
    public func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity, withChanges changes: ScheduledMeetingChangesEntity) async throws -> ScheduledMeetingEntity {
        try await withAsyncThrowingValue(in: { completion in
            chatSDK.updateScheduledMeeting(
                meeting.chatId,
                scheduledId: meeting.scheduledId,
                timezone: changes.timezone ?? meeting.timezone,
                startDate: Int(changes.startDate?.timeIntervalSince1970 ?? meeting.startDate.timeIntervalSince1970),
                endDate: Int(changes.endDate?.timeIntervalSince1970 ?? meeting.endDate.timeIntervalSince1970),
                title: changes.title ?? meeting.title,
                description: changes.description ?? meeting.description,
                cancelled: changes.cancelled ?? meeting.cancelled,
                flags: meeting.flags.toMEGAChatScheduledFlags(),
                rules: changes.rules?.toMEGAChatScheduledRules() ?? (meeting.rules.frequency == .invalid ? nil : meeting.rules.toMEGAChatScheduledRules()),
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success(let request):
                        guard let scheduledMeeting = request.scheduledMeetingList.first?.toScheduledMeetingEntity() else {
                            completion(.failure(ScheduleMeetingErrorEntity.scheduledMeetingNotFound))
                            return
                        }
                        completion(.success(scheduledMeeting))
                    case .failure:
                        completion(.failure(ScheduleMeetingErrorEntity.invalidArguments))
                    }
                })
            )
        })
    }
    
    public func updateScheduleMeetingOccurrence(_ occurrence: ScheduledMeetingOccurrenceEntity, inChatRoom chatRoom: ChatRoomEntity, withChanges changes: ScheduledMeetingOccurrenceChangesEntity) async throws -> ScheduledMeetingEntity {
        try await withAsyncThrowingValue(in: { completion in
            chatSDK.updateScheduledMeetingOccurrence(
                chatRoom.chatId,
                scheduledId: occurrence.scheduledId,
                overrides: UInt64(changes.startDate?.timeIntervalSince1970 ?? occurrence.startDate.timeIntervalSince1970),
                newStartDate: UInt64(occurrence.startDate.timeIntervalSince1970),
                newEndDate: UInt64(changes.endDate?.timeIntervalSince1970 ?? occurrence.endDate.timeIntervalSince1970),
                newCancelled: changes.cancelled ?? false,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success(let request):
                        guard let scheduledMeeting = request.scheduledMeetingList.first?.toScheduledMeetingEntity() else {
                            completion(.failure(ScheduleMeetingErrorEntity.scheduledMeetingNotFound))
                            return
                        }
                        completion(.success(scheduledMeeting))
                    case .failure:
                        completion(.failure(ScheduleMeetingErrorEntity.invalidArguments))
                    }
                })
            )
        })
    }
}
