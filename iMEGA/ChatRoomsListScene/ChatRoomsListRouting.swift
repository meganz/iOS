import MEGADomain

@MainActor
protocol ChatRoomsListRouting {
    var navigationController: UINavigationController? { get }
    func presentStartConversation()
    func presentMeetingAlreadyExists()
    func presentCreateMeeting()
    func presentEnterMeeting()
    func presentScheduleMeeting()
    func presentWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity)
    func showInviteContactScreen()
    func showDetails(forChatId chatId: HandleEntity)
    func openChatRoom(withChatId chatId: ChatIdEntity, publicLink: String?)
    func present(alert: UIAlertController, animated: Bool)
    func presentMoreOptionsForChat(
        withDNDEnabled dndEnabled: Bool,
        dndAction: @escaping () -> Void,
        markAsReadAction: (() -> Void)?,
        infoAction: @escaping () -> Void,
        archiveAction: @escaping () -> Void
    )
    func showGroupChatInfo(forChatRoom chatRoom: ChatRoomEntity)
    func showNoteToSelfInfo(noteToSelfChat: ChatRoomEntity)
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity)
    func showMeetingOccurrences(for scheduledMeeting: ScheduledMeetingEntity)
    func showContactDetailsInfo(forUseHandle userHandle: HandleEntity, userEmail: String)
    func showArchivedChatRooms()
    func openCallView(for call: CallEntity, in chatRoom: ChatRoomEntity)
    func showErrorMessage(_ message: String)
    func showSuccessMessage(_ message: String)
    func edit(scheduledMeeting: ScheduledMeetingEntity)
    func hideAds()
    func openUserProfile()
}
