import MEGADomain

class ScheduleMeetingUpdateViewConfiguration: ScheduleMeetingViewConfigurable {
    let scheduledMeeting: ScheduledMeetingEntity
    
    var type: ScheduleMeetingViewConfigurationType { .edit }
    var meetingName: String { scheduledMeeting.title }
    var startDate: Date { scheduledMeeting.startDate }
    var endDate: Date { scheduledMeeting.endDate }
    var meetingDescription: String { scheduledMeeting.description }
    var calendarInviteEnabled: Bool { scheduledMeeting.flags.emailsEnabled }
    var rules: ScheduledMeetingRulesEntity { scheduledMeeting.rules }
    var participantHandleList: [HandleEntity] { participantHandleListInChatRoom() }
    var meetingLinkEnabled: Bool = false
    
    var shouldAllowEditingMeetingName: Bool { true }
    var shouldAllowEditingRecurrenceOption: Bool { true }
    var shouldAllowEditingEndRecurrenceOption: Bool { true }
    var shouldAllowEditingMeetingLink: Bool { true }
    var shouldAllowEditingParticipants: Bool { true }
    var shouldAllowEditingCalendarInvite: Bool { true }
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { true }
    var shouldAllowEditingMeetingDescription: Bool { true }

    var allowNonHostsToAddParticipantsEnabled: Bool {
        guard let chatroom = try? chatRoom(for: scheduledMeeting) else { return false }
        return chatroom.isOpenInviteEnabled
    }
        
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatLinkUseCase: any ChatLinkUseCaseProtocol
    private(set) var scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol

    init(
        scheduledMeeting: ScheduledMeetingEntity,
        chatRoomUseCase: any ChatRoomUseCaseProtocol,
        chatLinkUseCase: any ChatLinkUseCaseProtocol,
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    ) {
        self.scheduledMeeting = scheduledMeeting
        self.chatRoomUseCase = chatRoomUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
    }
    
    func updateMeetingLinkEnabled() async {
        do {
            let chatRoom = try chatRoom(for: scheduledMeeting)
            _ = try await chatLinkUseCase.queryChatLink(for: chatRoom)
            meetingLinkEnabled = true
        } catch {
            MEGALogError("query chat link failed with error: \(error)")
            meetingLinkEnabled = false
        }
    }
    
    func submit(meeting: ScheduleMeetingProxyEntity) async throws -> ScheduleMeetingViewConfigurationCompletion {
        var updatedScheduledMeeting = updateScheduledMeeting(meeting)
        updatedScheduledMeeting = try await scheduledMeetingUseCase.updateScheduleMeeting(updatedScheduledMeeting)
        try await renameChatRoom(meeting: meeting)
        try updateParticipants(with: meeting)
        try await updateMeetingLinkIfNeeded(meeting: meeting)
        try await updateAllowNonHostsToAddParticipantsEnabled(meeting: meeting)
        return .showMessageForScheduleMeeting(
            message: Strings.Localizable.Meetings.ScheduleMeeting.UpdateSuccessfull.popupMessage,
            scheduledMeeting: updatedScheduledMeeting
        )
    }
    
    private func updateParticipants(with meeting: ScheduleMeetingProxyEntity) throws {
        let participantHandleList = meeting.participantHandleList
        let participantHandleListInChatRoom = participantHandleListInChatRoom()
        let chatRoom = try chatRoom(for: scheduledMeeting)
        
        Set(participantHandleListInChatRoom)
            .subtracting(participantHandleList)
            .forEach { chatRoomUseCase.remove(fromChat: chatRoom, userId: $0) }
        
        Set(participantHandleList)
            .subtracting(participantHandleListInChatRoom)
            .forEach { chatRoomUseCase.invite(toChat: chatRoom, userId: $0) }
    }
    
    private func participantHandleListInChatRoom() -> [HandleEntity] {
        guard let chatroom = try? chatRoom(for: scheduledMeeting) else {
            return []
        }
        
        return chatRoomUseCase.peerHandles(forChatRoom: chatroom)
    }
    
    private func updateAllowNonHostsToAddParticipantsEnabled(meeting: ScheduleMeetingProxyEntity) async throws {
        guard allowNonHostsToAddParticipantsEnabled != meeting.allowNonHostsToAddParticipantsEnabled else { return }
        let result = try await chatRoomUseCase.allowNonHostToAddParticipants(
            meeting.allowNonHostsToAddParticipantsEnabled,
            forChatRoom: try chatRoom(for: scheduledMeeting)
        )
        MEGALogInfo("Updated allowNonHostToAddParticipants: \(result)")
    }
    
    private func updateMeetingLinkIfNeeded(meeting: ScheduleMeetingProxyEntity) async throws {
        guard meetingLinkEnabled != meeting.meetingLinkEnabled else { return }
        if meeting.meetingLinkEnabled {
            let meetingLink = try await createMeetingLink()
            MEGALogInfo("Meeting link: \(meetingLink)")
        } else {
            try await removeMeetingLink()
        }
    }
    
    private func createMeetingLink() async throws -> String {
        try await chatLinkUseCase.createChatLink(for: try chatRoom(for: scheduledMeeting))
    }
    
    private func removeMeetingLink() async throws {
        try await chatLinkUseCase.removeChatLink(for: try chatRoom(for: scheduledMeeting))
    }
    
    private func chatRoom(for scheduledMeeting: ScheduledMeetingEntity) throws -> ChatRoomEntity {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else {
            throw ChatRoomErrorEntity.noChatRoomFound
        }
        
        return chatRoom
    }
    
    private func renameChatRoom(meeting: ScheduleMeetingProxyEntity) async throws {
        guard scheduledMeeting.title != meeting.title else { return }
        _ = try await chatRoomUseCase.renameChatRoom(try chatRoom(for: scheduledMeeting), title: meeting.title)
    }
    
    private func updateScheduledMeeting(_ meeting: ScheduleMeetingProxyEntity) -> ScheduledMeetingEntity {
        ScheduledMeetingEntity(
            cancelled: scheduledMeeting.cancelled,
            new: scheduledMeeting.new,
            deleted: scheduledMeeting.deleted,
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            parentScheduledId: scheduledMeeting.parentScheduledId,
            organizerUserId: scheduledMeeting.organizerUserId,
            timezone: scheduledMeeting.timezone,
            startDate: meeting.startDate,
            endDate: meeting.endDate,
            title: meeting.title,
            description: meeting.description,
            attributes: scheduledMeeting.attributes,
            overrides: scheduledMeeting.overrides,
            flags: ScheduledMeetingFlagsEntity(emailsEnabled: meeting.calendarInvite),
            rules: meeting.rules ?? .init(frequency: .invalid)
        )
    }
}
