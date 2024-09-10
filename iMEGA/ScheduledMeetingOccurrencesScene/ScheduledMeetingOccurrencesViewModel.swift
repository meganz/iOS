import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

@MainActor
protocol ScheduledMeetingOccurrencesRouting {
    func showErrorMessage(_ message: String)
    func showSuccessMessage(_ message: String)
    func showSuccessMessageAndDismiss(_ message: String)
    func edit(
        occurrence: ScheduledMeetingOccurrenceEntity
    ) -> AnyPublisher<ScheduledMeetingOccurrenceEntity, Never>
}

@MainActor
final class ScheduledMeetingOccurrencesViewModel: ObservableObject {
    private let router: any ScheduledMeetingOccurrencesRouting
    private var scheduledMeeting: ScheduledMeetingEntity
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    private var lastOccurrenceDate = Date()
    private var maxOccurrencesLoaded = 0
    var occurrences: [ScheduledMeetingOccurrenceEntity] = []
    var selectedOccurrence: ScheduleMeetingOccurrence?
    
    @Published var title: String
    @Published var subtitle: String?
    @Published var displayOccurrences: [ScheduleMeetingOccurrence] = []
    @Published var seeMoreOccurrencesVisible: Bool = true
    @Published var showCancelMeetingAlert = false
    
    private(set) var contextMenuOptions: [OccurrenceContextMenuOption]?
    
    private let maxOccurrencesBatchCount = 20
    private var subscriptions = Set<AnyCancellable>()
    var chatHasMessagesSubscription: AnyCancellable?
    
    var chatHasMessages = false
    
    private var chatRoom: ChatRoomEntity? {
        chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId)
    }
    
    init(
        router: some ScheduledMeetingOccurrencesRouting,
        scheduledMeeting: ScheduledMeetingEntity,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    ) {
        self.router = router
        self.scheduledMeeting = scheduledMeeting
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomAvatarViewModel = chatRoomAvatarViewModel
        title = scheduledMeeting.title
        contextMenuOptions = constructContextMenuOptions()
        
        updateSubtitle()
        listenToOccurrencesUpdate()
    }
    
    func didLoadView() async {
        await fetchOccurrences()
    }
    
    // MARK: - Public
    func seeMoreTapped() async {
        await fetchOccurrences()
    }
    
    func cancelMeetingAlertData() -> CancelMeetingAlertDataModel {
        let hasMessagesDescriptionString = chatHasMessages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.WithMessages.description : Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.WithoutMessages.description
        return CancelMeetingAlertDataModel(
            title: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.title(selectedOccurrence?.date ?? "") : Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.title,
            message: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.description : hasMessagesDescriptionString,
            primaryButtonTitle: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Option.confirm : Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withMessages,
            primaryButtonAction: {
                Task {
                    await self.confirmCancelOccurrence()
                }
            },
            secondaryButtonTitle: Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.dontCancel)
    }
    
    // MARK: - Private
    private func updateSubtitle() {
        switch scheduledMeeting.rules.frequency {
        case .invalid:
            MEGALogError("A recurring meeting must have frequency")
        case .daily:
            subtitle = Strings.Localizable.Meetings.Scheduled.Recurring.Frequency.daily
        case .weekly:
            subtitle = Strings.Localizable.Meetings.Scheduled.Recurring.Frequency.weekly
        case .monthly:
            subtitle = Strings.Localizable.Meetings.Scheduled.Recurring.Frequency.monthly
        }
    }
    
    private func fetchOccurrences() async {
        do {
            let occurrences = try await scheduledMeetingUseCase.scheduledMeetingOccurrencesByChat(
                chatId: scheduledMeeting.chatId,
                since: lastOccurrenceDate
            )
            await manageFetchedOccurrences(occurrences)
        } catch {
            MEGALogError("Error fetching occurrences for scheduled meeting: \(scheduledMeeting.title)")
        }
    }
    
    private func refreshOccurrences() async {
        lastOccurrenceDate = Date()
        occurrences = []
        await fetchOccurrences()
    }
    
    private func manageFetchedOccurrences(_ fetchedOccurrences: [ScheduledMeetingOccurrenceEntity]) async {
        seeMoreOccurrencesVisible = fetchedOccurrences.count >= maxOccurrencesBatchCount
        lastOccurrenceDate = fetchedOccurrences.last?.startDate ?? Date()
        
        let filteredOccurrences = fetchedOccurrences.filter { !$0.cancelled && !occurrences.contains($0) }
        occurrences.append(contentsOf: filteredOccurrences)
        
        if occurrences.count >= maxOccurrencesLoaded {
            maxOccurrencesLoaded = occurrences.count
            populateOccurrences()
        } else {
            await fetchOccurrences()
        }
    }
    
    private func populateOccurrences() {
        displayOccurrences = occurrences.map(scheduleMeetingOccurrence(from:))
    }
    
    private func scheduleMeetingOccurrence(
        from occurrence: ScheduledMeetingOccurrenceEntity
    ) -> ScheduleMeetingOccurrence {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        let date = dateFormatter.localisedString(from: occurrence.startDate)
        
        let timeFormatter = DateFormatter.timeShort()
        let time = timeFormatter.localisedString(from: occurrence.startDate)
        + " - "
        + timeFormatter.localisedString(from: occurrence.endDate)
        
        return ScheduleMeetingOccurrence(
            id: UUID().uuidString,
            date: date,
            title: scheduledMeeting.title,
            time: time
        )
    }
    
    private func constructContextMenuOptions() -> [OccurrenceContextMenuOption] {
        
        guard
            let chatRoom,
            chatRoom.ownPrivilege == .moderator
        else {
            return []
        }
        
        let edit = OccurrenceContextMenuOption(
            title: Strings.Localizable.edit,
            image: .edittext,
            action: editOccurrence
        )
        
        let cancelOccurrence = OccurrenceContextMenuOption(
            title: Strings.Localizable.Meetings.Scheduled.ContextMenu.cancel,
            image: .rubbishBin,
            action: cancelOccurrenceTapped
        )
        
        return [
            edit,
            cancelOccurrence
        ]
    }
    
    private func editOccurrence(_ occurrence: ScheduleMeetingOccurrence) {
            guard let occurrenceIndex = displayOccurrences.firstIndex(of: occurrence) else {
                return
            }
            
            let occurrence = occurrences[occurrenceIndex]
            router
                .edit(occurrence: occurrence)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task {
                        await self.refreshOccurrences()
                    }
                }
                .store(in: &subscriptions)
    }
    
    private func cancelOccurrenceTapped(_ occurrence: ScheduleMeetingOccurrence) {
        selectedOccurrence = occurrence
        guard let chatRoom  else { return }
        subscribeToMessagesLoaded(in: chatRoom)
        checkIfChatHasMessages(for: chatRoom)
    }
    
    private func checkIfChatHasMessages(for chatRoom: ChatRoomEntity) {
        let source = chatRoomUseCase.loadMessages(for: chatRoom, count: 10)
        if source == .none {
            chatHasMessages(chatRoom, false)
        }
    }
    
    private func subscribeToMessagesLoaded(in chatRoom: ChatRoomEntity) {
        chatHasMessagesSubscription = chatRoomUseCase.chatMessageLoaded(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] message in
                guard let self else { return }
                guard let message else {
                    checkIfChatHasMessages(for: chatRoom)
                    return
                }
                
                if !message.managementMessage {
                    chatHasMessages(chatRoom, true)
                }
            })
    }
    
    private func chatHasMessages(_ chatRoom: ChatRoomEntity, _ hasMessages: Bool) {
        cancelChatHasMessageSubscription()
        closeChat(chatRoom)
        chatHasMessages = hasMessages
        showCancelMeetingAlert = true
    }
    
    private func cancelChatHasMessageSubscription() {
        chatHasMessagesSubscription?.cancel()
        chatHasMessagesSubscription = nil
    }
    
    private func closeChat(_ chatRoom: ChatRoomEntity) {
        chatRoomUseCase.closeChatRoom(chatRoom)
    }
    
    private func confirmCancelOccurrence() async {
        if occurrences.count == 1 {
            await cancelScheduledMeeting()
        } else {
            await cancelScheduledMeetingOccurrence()
        }
    }
    
    func cancelScheduledMeeting() async {
        do {
            var scheduledMeeting = scheduledMeeting
            scheduledMeeting.cancelled = true
            scheduledMeeting = try await scheduledMeetingUseCase.updateScheduleMeeting(scheduledMeeting, updateChatTitle: false)
            if !chatHasMessages {
                await archiveChatRoom()
            } else {
                router.showSuccessMessageAndDismiss(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withMessages)
            }
        } catch {
            router.showErrorMessage(Strings.Localizable.somethingWentWrong)
            MEGALogError("Failed to cancel meeting")
        }
    }
    
    private func archiveChatRoom() async {
        do {
            guard let chatRoom else { return }
            _ = try await chatRoomUseCase.archive(true, chatRoom: chatRoom)
            router.showSuccessMessageAndDismiss(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withoutMessages)
        } catch {
            router.showErrorMessage(Strings.Localizable.somethingWentWrong)
            MEGALogError("Failed to archive chat")
        }
    }
    
    func cancelScheduledMeetingOccurrence() async {
        do {
            guard let selectedOccurrence,
                  let occurrenceIndex = displayOccurrences.firstIndex(of: selectedOccurrence) else {
                return
            }
            
            var occurrence = occurrences[occurrenceIndex]
            occurrence.cancelled = true
            occurrence.overrides = UInt64(occurrence.startDate.timeIntervalSince1970)
            scheduledMeeting = try await scheduledMeetingUseCase.updateOccurrence(occurrence, meeting: scheduledMeeting)
            updateListWithDeletedIndex(occurrenceIndex)
        } catch {
            router.showErrorMessage(Strings.Localizable.somethingWentWrong)
            MEGALogError("Failed to cancel meeting occurrence")
        }
    }
    
    private func updateListWithDeletedIndex(_ index: Int) {
        displayOccurrences.remove(at: index)
        occurrences.remove(at: index)
        maxOccurrencesLoaded -= 1
        router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.success(selectedOccurrence?.date ?? ""))
    }
    
    private func listenToOccurrencesUpdate() {
        guard let chatRoom else { return }
        scheduledMeetingUseCase.occurrencesShouldBeReloadListener(forChatRoom: chatRoom)
            .sink { [weak self] shouldReload in
                guard let self else {
                    return
                }
                if shouldReload {
                    Task {
                        await self.refreshOccurrences()
                    }
                }
            }
            .store(in: &subscriptions)
    }
}
