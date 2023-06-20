import MEGADomain
import MEGAFoundation
import Combine

protocol ScheduleMeetingRouting {
    func showSpinner()
    func hideSpinner()
    func discardChanges()
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void))
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity)
    func showRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>?
    func showEndRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>?
}

final class ScheduleMeetingViewModel: ObservableObject {
    
    enum Constants {
        static let meetingNameMaxLenght: Int = 30
        static let meetingDescriptionMaxLenght: Int = 3000
        static let minDurationFiveMinutes: TimeInterval = 300
        static let defaultDurationHalfHour: TimeInterval = 1800
    }
    
    private let router: ScheduleMeetingRouting
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private var chatLinkUseCase: any ChatLinkUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol

    @Published var startDate = Date() {
        didSet {
            startDateUpdated()
        }
    }
    @Published var startDatePickerVisible = false
    lazy var startDateFormatted = formatDate(startDate)
    @Published var endDate = Date() {
        didSet {
            endDateFormatted = formatDate(endDate)
        }
    }
    @Published var endDatePickerVisible = false
    lazy var endDateFormatted = formatDate(endDate)
    var minimunEndDate = Date()
    
    @Published var meetingName = "" {
        didSet {
            meetingNameTooLong = meetingName.count > Constants.meetingNameMaxLenght
            configureCreateButton()
        }
    }
    @Published var meetingNameTooLong = false
    
    @Published var meetingDescription = "" {
        didSet {
            meetingDescriptionTooLong = meetingDescription.count > Constants.meetingDescriptionMaxLenght
            configureCreateButton()
        }
    }
    @Published var meetingDescriptionTooLong = false
    
    @Published var meetingLinkEnabled = false
    @Published var calendarInviteEnabled = false
    @Published var allowNonHostsToAddParticipantsEnabled = true
    
    @Published var showDiscardAlert = false
    @Published var createButtonEnabled = false
    
    let timeFormatter: some DateFormatting = DateFormatter.timeShort()
    let dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    
    private var participants = [UserEntity]() {
        didSet {
            participantsCount = participants.count
        }
    }
    @Published var participantsCount = 0
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    
    var monthlyRecurrenceFootnoteViewText: String? {
        guard rules.frequency == .monthly, let day = rules.monthDayList?.first else { return nil }
        
        switch day {
        case 29:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayTwentyNineSelected.footNote
        case 30:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtySelected.footNote
        case 31:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtyFirstSelected.footNote
        default:
            return nil
        }
    }
    
    init(router: ScheduleMeetingRouting,
         rules: ScheduledMeetingRulesEntity,
         scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
         chatLinkUseCase: any ChatLinkUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol) {
        self.router = router
        self.rules = rules
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.startDate = nextDateMinutesIsFiveMultiple(startDate)
        self.endDate = startDate.addingTimeInterval(Constants.defaultDurationHalfHour)
    }
    
    // MARK: - Public
    func createDidTap() {
        createScheduleMeeting()
    }
    
    func startsDidTap() {
        startDatePickerVisible.toggle()
        endDatePickerVisible = false
    }
    
    func endsDidTap() {
        endDatePickerVisible.toggle()
        startDatePickerVisible = false
    }
    
    func cancelDidTap() {
        showDiscardAlert = true
    }
    
    func discardChangesTap() {
        router.discardChanges()
    }
    
    func keepEditingTap() {
        showDiscardAlert = false
    }
    
    func addParticipantsTap() {
        router.showAddParticipants(alreadySelectedUsers: participants) { [weak self] userEntities in
            self?.participants = userEntities ?? []
        }
    }
    
    func showRecurrenceOptionsView() {
        router
            .showRecurrenceOptionsView(rules: rules, startDate: startDate)?
            .assign(to: &$rules)
    }
    
    func selectedFrequencyDetails() -> String {
        ScheduleMeetingSelectedFrequencyDetails(rules: rules, startDate: startDate).string
    }
    
    func showEndRecurrenceOptionsView() {
        router
            .showEndRecurrenceOptionsView(rules: rules, startDate: startDate)?
            .assign(to: &$rules)
    }
    
    func endRecurrenceDetailText() -> String {
        if let untilDate = rules.until {
            return dateFormatter.localisedString(from: untilDate)
        } else {
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        }
    }
    
    // MARK: - Private
    private func formatDate(_ date: Date) -> String {
        dateFormatter.localisedString(from: date) + " " + timeFormatter.localisedString(from: date)
    }
    
    private func configureCreateButton() {
        createButtonEnabled = meetingName.count > 0 && !meetingNameTooLong && !meetingDescriptionTooLong
    }
    
    private func nextDateMinutesIsFiveMultiple(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: date)
        guard let minutes = components.minute else {
            return date
        }
        components.minute = (minutes + 4) / 5 * 5
        return calendar.date(from: components) ?? date
    }
    
    private func startDateUpdated() {
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(Constants.defaultDurationHalfHour)
            endDateFormatted = formatDate(endDate)
        }
        minimunEndDate = startDate.addingTimeInterval(Constants.minDurationFiveMinutes)
        startDateFormatted = formatDate(startDate)
        if let untilDate = rules.until, untilDate < startDate {
            rules.until = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: startDate)
        }
        rules.updateDayList(usingStartDate: startDate)
    }
    
    private func constructCreateScheduleMeetingEntity() -> CreateScheduleMeetingEntity {
        return CreateScheduleMeetingEntity(
            title: meetingName,
            description: meetingDescription,
            participants: participants,
            calendarInvite: calendarInviteEnabled,
            openInvite: allowNonHostsToAddParticipantsEnabled,
            startDate: startDate,
            endDate: endDate,
            rules: rules.frequency == .invalid ? nil : rules
        )
    }
    
    private func createScheduleMeeting() {
        router.showSpinner()
        Task { [weak self] in
            guard let self else { return }
            do {
                let createScheduleMeeting = constructCreateScheduleMeetingEntity()
                let scheduledMeeting = try await scheduledMeetingUseCase.createScheduleMeeting(createScheduleMeeting)
                await createLinkIfNeeded(chatId: scheduledMeeting.chatId)
                await scheduleMeetingCreationComplete(scheduledMeeting)
            } catch {
                router.hideSpinner()
                MEGALogDebug("Failed to create scheduled meeting with \(error)")
            }
        }
    }
    
    private func createLinkIfNeeded(chatId: ChatIdEntity) async {
        if meetingLinkEnabled {
            do {
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
                _ = try await chatLinkUseCase.createChatLink(for: chatRoom)
            } catch {
                router.hideSpinner()
                MEGALogDebug("Failed to create link meeting with \(error)")
            }
        }
    }
    
    @MainActor
    private func scheduleMeetingCreationComplete(_ scheduledMeeting: ScheduledMeetingEntity) {
        self.router.showMeetingInfo(for: scheduledMeeting)
    }
}
