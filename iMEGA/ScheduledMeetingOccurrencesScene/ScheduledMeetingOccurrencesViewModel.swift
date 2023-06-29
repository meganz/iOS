import Combine
import MEGADomain

protocol ScheduledMeetingOccurrencesRouting {
    func showErrorMessage(_ message: String)
    func showSuccessMessage(_ message: String)
    func showSuccessMessageAndDismiss(_ message: String)
    func edit(
        occurrence: ScheduledMeetingOccurrenceEntity
    ) -> AnyPublisher<ScheduledMeetingOccurrenceEntity, Never>
}

final class ScheduledMeetingOccurrencesViewModel: ObservableObject {
    private let router: ScheduledMeetingOccurrencesRouting
    private var scheduledMeeting: ScheduledMeetingEntity
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    private var lastOccurrenceDate = Date()
    var occurrences: [ScheduledMeetingOccurrenceEntity] = []
    var selectedOccurrence: ScheduleMeetingOccurence?

    @Published var title: String
    @Published var subtitle: String?
    @Published var displayOccurrences: [ScheduleMeetingOccurence] = []
    @Published private(set) var primaryAvatar: UIImage?
    @Published private(set) var secondaryAvatar: UIImage?
    @Published var seeMoreOccurrencesVisible: Bool = true
    @Published var showCancelMeetingAlert = false
    
    private(set) var contextMenuOptions: [OccurrenceContextMenuOption]?
    
    private let maxOccurrencesBatchCount = 20
    private var subscriptions = Set<AnyCancellable>()
    var chatHasMessagesSubscription: AnyCancellable?
    
    var chatHasMeesages = false
    
    init(router: ScheduledMeetingOccurrencesRouting,
         scheduledMeeting: ScheduledMeetingEntity,
         scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    ) {
        self.router = router
        self.scheduledMeeting = scheduledMeeting
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomAvatarViewModel = chatRoomAvatarViewModel
        
        self.title = scheduledMeeting.title
        self.primaryAvatar = chatRoomAvatarViewModel?.primaryAvatar
        self.secondaryAvatar = chatRoomAvatarViewModel?.secondaryAvatar
        
        contextMenuOptions = constructContextMenuOptions()
        
        updateSubtitle()
        fetchOccurrences()
    }

    // MARK: - Public
    func seeMoreTapped() {
        fetchOccurrences()
    }

    func cancelMeetingAlertData() -> CancelMeetingAlertDataModel {
        let hasMessagesDescriptionString = chatHasMeesages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.WithMessages.description : Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.WithoutMessages.description
        return CancelMeetingAlertDataModel(
            title: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.title(selectedOccurrence?.date ?? "") : Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Last.title,
            message: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.description : hasMessagesDescriptionString,
            primaryButtonTitle: occurrences.count != 1 ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.Option.confirm : Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withMessages,
            primaryButtonAction: confirmCancelOccurrence,
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
    
    private func fetchOccurrences() {
        Task {
            do {
                var occurrences = try await scheduledMeetingUseCase.scheduledMeetingOccurrencesByChat(chatId: scheduledMeeting.chatId, since: lastOccurrenceDate)
                await populateOccurrences(occurrences)
            } catch {
                MEGALogError("Error fetching occurrences for scheduled meeting: \(scheduledMeeting.title)")
            }
        }
    }
    
    @MainActor
    private func populateOccurrences(_ newOccurrences: [ScheduledMeetingOccurrenceEntity]) {
        seeMoreOccurrencesVisible = newOccurrences.count >= maxOccurrencesBatchCount
        lastOccurrenceDate = newOccurrences.last?.startDate ?? Date()

        let filteredOccurrences = newOccurrences.filter { !$0.cancelled }
        occurrences.append(contentsOf: filteredOccurrences)

        let newDisplayOccurrences = filteredOccurrences.map(scheduleMeetingOccurrence(from:))
        displayOccurrences.append(contentsOf: newDisplayOccurrences)
    }
    
    private func scheduleMeetingOccurrence(
        from occurrence: ScheduledMeetingOccurrenceEntity
    ) -> ScheduleMeetingOccurence {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        let date = dateFormatter.localisedString(from: occurrence.startDate)
        
        let timeFormatter = DateFormatter.timeShort()
        let time = timeFormatter.localisedString(from: occurrence.startDate)
        + " - "
        + timeFormatter.localisedString(from: occurrence.endDate)
        
        return ScheduleMeetingOccurence(
            id: UUID().uuidString,
            date: date,
            title: scheduledMeeting.title,
            time: time
        )
    }
    
    private func constructContextMenuOptions() -> [OccurrenceContextMenuOption] {
        var options: [OccurrenceContextMenuOption] = []
        
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId), chatRoom.ownPrivilege == .moderator {
            options.append(
                OccurrenceContextMenuOption(
                    title: Strings.Localizable.Meetings.Scheduled.ContextMenu.cancel,
                    imageName: Asset.Images.NodeActions.rubbishBin.name
                ) { [weak self] occurrence in
                    guard let self else { return }
                    cancelOccurrenceTapped(occurrence)
                }
            )
            
            options.append(
                OccurrenceContextMenuOption(
                    title: Strings.Localizable.edit,
                    imageName: Asset.Images.NodeActions.edittext.name
                ) { [weak self] occurrence in
                    guard let self,
                            let occurrenceIndex = displayOccurrences.firstIndex(of: occurrence) else {
                        return
                    }
                    
                    let occurrence = occurrences[occurrenceIndex]
                    router
                        .edit(occurrence: occurrence)
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] updatedOccurrence in
                            guard let self else { return }
                            reload(occurrence: updatedOccurrence, at: occurrenceIndex)
                        }
                        .store(in: &subscriptions)
                }
            )
        }
        
        return options
    }
        
    private func reload(occurrence: ScheduledMeetingOccurrenceEntity, at index: Int) {
        occurrences[index] = occurrence
        displayOccurrences[index] = scheduleMeetingOccurrence(from: occurrence)
        
        occurrences.sort { $0.startDate < $1.startDate }
        displayOccurrences = occurrences.map(scheduleMeetingOccurrence(from:))
    }
    
    private func cancelOccurrenceTapped(_ occurrence: ScheduleMeetingOccurence) {
        selectedOccurrence = occurrence
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else { return }
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
        cancelChatHasMessageSuscription()
        closeChat(chatRoom)
        chatHasMeesages = hasMessages
        showCancelMeetingAlert = true
    }
    
    private func cancelChatHasMessageSuscription() {
        chatHasMessagesSubscription?.cancel()
        chatHasMessagesSubscription = nil
    }
    
    private func closeChat(_ chatRoom: ChatRoomEntity) {
        chatRoomUseCase.closeChatRoom(chatRoom)
    }
    
    private func confirmCancelOccurrence() {
        if occurrences.count == 1 {
            cancelScheduledMeeting()
        } else {
           cancelScheduledMeetingOccurrence()
        }
    }
    
    func cancelScheduledMeeting() {
        Task {
            do {
                var scheduledMeeting = scheduledMeeting
                scheduledMeeting.cancelled = true
                self.scheduledMeeting = try await scheduledMeetingUseCase.updateScheduleMeeting(scheduledMeeting)
                if !chatHasMeesages {
                   archiveChatRoom()
                } else {
                    router.showSuccessMessageAndDismiss(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withMessages)
                }
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to cancel meeting")
            }
        }
    }
    
    private func archiveChatRoom() {
        Task {
            do {
                guard let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else { return }
                _ = try await chatRoomUseCase.archive(true, chatRoom: chatRoom)
                router.showSuccessMessageAndDismiss(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withoutMessages)
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to archive chat")
            }
        }
    }
    
    func cancelScheduledMeetingOccurrence() {
        Task {
            do {
                guard let selectedOccurrence,
                        let occurrenceIndex = displayOccurrences.firstIndex(of: selectedOccurrence) else {
                    return
                }
                
                var occurrence = occurrences[occurrenceIndex]
                occurrence.cancelled = true
                occurrence.overrides = UInt64(occurrence.startDate.timeIntervalSince1970)
                scheduledMeeting = try await scheduledMeetingUseCase.updateOccurrence(occurrence, meeting: scheduledMeeting)
                await updateListWithDeletedIndex(occurrenceIndex)
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to cancel meeting occurrence")
            }
        }
    }
    
    @MainActor private func updateListWithDeletedIndex(_ index: Int) {
        displayOccurrences.remove(at: index)
        occurrences.remove(at: index)
        router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Occurrence.success(selectedOccurrence?.date ?? ""))
    }
}
