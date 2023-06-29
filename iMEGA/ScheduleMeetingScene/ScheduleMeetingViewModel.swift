import Combine
import MEGADomain
import MEGAFoundation

protocol ScheduleMeetingRouting {
    func showSpinner()
    func hideSpinner()
    func dismiss(animated: Bool) async
    func showSuccess(message: String) async
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity)
    func updated(occurrence: ScheduledMeetingOccurrenceEntity)
    func updated(meeting: ScheduledMeetingEntity)
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void))
    func showRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>?
    func showEndRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>?
}

final class ScheduleMeetingViewModel: ObservableObject {
    
    enum Constants {
        static let meetingNameMaxLength: Int = 30
        static let meetingDescriptionMaxLength: Int = 3000
        static let minDurationFiveMinutes: TimeInterval = 300
    }
    
    lazy var startDateFormatted = formatDate(startDate)
    lazy var endDateFormatted = formatDate(endDate)
    var minimunEndDate: Date { startDate.addingTimeInterval(Constants.minDurationFiveMinutes) }
    let timeFormatter: some DateFormatting = DateFormatter.timeShort()
    let dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    var trimmedMeetingName: String { trim(meetingName) }
    var trimmedMeetingDescription: String { trim(meetingDescription) }
    var isNewMeeting: Bool { viewConfiguration.type == .new }
    var participantsCount: Int { participantHandleList.count }
    
    var shouldAllowEditingMeetingName: Bool { viewConfiguration.shouldAllowEditingMeetingName }
    var shouldAllowEditingRecurrenceOption: Bool { viewConfiguration.shouldAllowEditingRecurrenceOption }
    var shouldAllowEditingEndRecurrenceOption: Bool { viewConfiguration.shouldAllowEditingEndRecurrenceOption }
    var shouldAllowEditingMeetingLink: Bool { viewConfiguration.shouldAllowEditingMeetingLink }
    var shouldAllowEditingParticipants: Bool { viewConfiguration.shouldAllowEditingParticipants }
    var shouldAllowEditingCalendarInvite: Bool { viewConfiguration.shouldAllowEditingCalendarInvite }
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { viewConfiguration.shouldAllowEditingAllowNonHostsToAddParticipants }
    var shouldAllowEditingMeetingDescription: Bool { viewConfiguration.shouldAllowEditingMeetingDescription }
    
    @Published var startDate: Date {
        didSet {
            startDateUpdated(previouslySelectedDate: oldValue)
            updateRightBarButtonState()
        }
    }
    
    @Published var endDate: Date {
        didSet {
            endDateFormatted = formatDate(endDate)
            updateRightBarButtonState()
        }
    }
    
    @Published var meetingName: String {
        didSet {
            meetingNameTooLong = meetingName.count > Constants.meetingNameMaxLength
            updateRightBarButtonState()
        }
    }
    
    @Published var meetingDescription: String {
        didSet {
            meetingDescriptionTooLong = meetingDescription.count > Constants.meetingDescriptionMaxLength
            updateRightBarButtonState()
        }
    }
    
    @Published var calendarInviteEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }
    
    @Published var allowNonHostsToAddParticipantsEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }
    
    @Published var meetingLinkEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }

    @Published var meetingNameTooLong = false
    @Published var startDatePickerVisible = false
    @Published var endDatePickerVisible = false
    @Published var meetingDescriptionTooLong = false
    @Published var meetingLinkToggleUIEnabled = true
    @Published var showDiscardAlert = false
    @Published var isRightBarButtonEnabled = false
    @Published var participantHandleList: [HandleEntity] = []
    
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
    
    @Published private(set) var rules: ScheduledMeetingRulesEntity

    private let router: ScheduleMeetingRouting
    private var viewConfiguration: any ScheduleMeetingViewConfigurable
    private var accountUseCase: any AccountUseCaseProtocol
    
    init(router: ScheduleMeetingRouting,
         viewConfiguration: any ScheduleMeetingViewConfigurable,
         accountUseCase: any AccountUseCaseProtocol) {
        self.router = router
        self.viewConfiguration = viewConfiguration
        self.accountUseCase = accountUseCase
        self.meetingName = viewConfiguration.meetingName
        self.meetingDescription = viewConfiguration.meetingDescription
        self.startDate = viewConfiguration.startDate
        self.endDate = viewConfiguration.endDate
        self.calendarInviteEnabled = viewConfiguration.calendarInviteEnabled
        self.allowNonHostsToAddParticipantsEnabled = viewConfiguration.allowNonHostsToAddParticipantsEnabled
        self.meetingLinkEnabled = viewConfiguration.meetingLinkEnabled
        self.rules = viewConfiguration.rules
        self.participantHandleList = viewConfiguration.participantHandleList
        self.updateMeetingLinkToggle()
    }
    
    // MARK: - Public
    func submitButtonTapped() {
        Task {
            do {
                await showSpinner()
                let scheduleMeetingProxy = makeScheduleMeetingProxyEntity()
                let completion = try await viewConfiguration.submit(meeting: scheduleMeetingProxy)
                await hideSpinner()
                await dismiss()
                await handle(completion: completion)
            } catch {
                MEGALogError("Enable to submit with error \(error)")
                await hideSpinner()
            }
        }
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
        guard hasUpdatedDetails() else {
            Task { await dismiss() }
            return
        }
        
        showDiscardAlert = true
    }
    
    func discardChangesTap() {
        Task { await dismiss() }
    }
    
    func keepEditingTap() {
        showDiscardAlert = false
    }
    
    func addParticipantsTap() {
        let participants = accountUseCase.contacts().filter { participantHandleList.contains($0.handle) }
        router.showAddParticipants(alreadySelectedUsers: participants) { [weak self] selectedParticipants in
            guard let self else { return }
            guard let selectedParticipants else {
                participantHandleList = []
                return
            }
            
            let removedParticipantHandleList = participants.compactMap { selectedParticipants.contains($0) ? nil : $0.handle }
            var participantHandleList = participantHandleList
            participantHandleList.removeAll { removedParticipantHandleList.contains($0) }
            self.participantHandleList = Array(Set(participantHandleList).union(selectedParticipants.map(\.handle)))
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
    
    func updateRightBarButtonState() {
        isRightBarButtonEnabled = hasUpdatedDetails()
        && !meetingNameTooLong
        && !meetingDescriptionTooLong
        && !trimmedMeetingName.isEmpty
    }
    
    // MARK: - Private
    
    @MainActor
    private func updated(occurrence: ScheduledMeetingOccurrenceEntity) {
        router.updated(occurrence: occurrence)
    }
    
    @MainActor
    private func updated(meeting: ScheduledMeetingEntity) {
        router.updated(meeting: meeting)
    }
    
    @MainActor
    private func handle(completion: ScheduleMeetingViewConfigurationCompletion) async {
        switch completion {
        case .showMessageForScheduleMeeting(let message, let scheduledMeeting):
            updated(meeting: scheduledMeeting)
            await showSuccess(message: message)
        case .showMessageForOccurrence(let message, let occurrence):
            updated(occurrence: occurrence)
            await showSuccess(message: message)
        case .showMessageAndNavigateToInfo(let message, let scheduledMeeting):
            showMeetingInfo(for: scheduledMeeting)
            await showSuccess(message: message)
        }
    }
    
    private func makeScheduleMeetingProxyEntity() -> ScheduleMeetingProxyEntity {
        ScheduleMeetingProxyEntity(
            title: trimmedMeetingName,
            description: trimmedMeetingDescription,
            participantHandleList: participantHandleList,
            meetingLinkEnabled: meetingLinkEnabled,
            calendarInvite: calendarInviteEnabled,
            allowNonHostsToAddParticipantsEnabled: allowNonHostsToAddParticipantsEnabled,
            startDate: startDate,
            endDate: endDate,
            rules: rules.frequency == .invalid ? nil : rules
        )
    }
    
    private func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func updateMeetingLinkToggle() {
        Task {
            await meetingLinkToggleUI(enable: false)
            await viewConfiguration.updateMeetingLinkEnabled()
            await meetingLink(enable: viewConfiguration.meetingLinkEnabled)
            await meetingLinkToggleUI(enable: true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        dateFormatter.localisedString(from: date) + " " + timeFormatter.localisedString(from: date)
    }
    
    private func hasUpdatedDetails() -> Bool {
        guard (trimmedMeetingName == viewConfiguration.meetingName
               || !viewConfiguration.shouldAllowEditingMeetingName)
                && startDate == viewConfiguration.startDate
                && endDate == viewConfiguration.endDate
                && (rules == viewConfiguration.rules
                    || !viewConfiguration.shouldAllowEditingRecurrenceOption)
                && (meetingLinkEnabled == viewConfiguration.meetingLinkEnabled
                    || !viewConfiguration.shouldAllowEditingMeetingLink)
                && (participantHandleList.count == viewConfiguration.participantHandleList.count
                    || !viewConfiguration.shouldAllowEditingParticipants)
                && (calendarInviteEnabled == viewConfiguration.calendarInviteEnabled
                    || !viewConfiguration.shouldAllowEditingCalendarInvite)
                && (allowNonHostsToAddParticipantsEnabled == viewConfiguration.allowNonHostsToAddParticipantsEnabled
                    || !viewConfiguration.shouldAllowEditingAllowNonHostsToAddParticipants)
                && (trimmedMeetingDescription == viewConfiguration.meetingDescription
                    || !viewConfiguration.shouldAllowEditingMeetingDescription) else {
            return true
        }
        
        return false
    }
    
    private func startDateUpdated(previouslySelectedDate: Date) {
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(1800)
            endDateFormatted = formatDate(endDate)
        }
        
        startDateFormatted = formatDate(startDate)
        updateRules(previouslySelectedDate: previouslySelectedDate)
    }
    
    private func updateRules(previouslySelectedDate: Date) {
        if let untilDate = rules.until, untilDate < startDate {
            rules.until = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: startDate)
        }
        
        let previouslySelectedRecurrenceOption = ScheduleMeetingCreationRecurrenceOption(
            rules: rules,
            startDate: previouslySelectedDate
        )
        
        guard previouslySelectedRecurrenceOption != .custom else { return }
        
        rules.updateDayList(usingStartDate: startDate)
    }
    
    @MainActor
    private func meetingLinkToggleUI(enable: Bool) {
        meetingLinkToggleUIEnabled = enable
    }
    
    @MainActor
    private func meetingLink(enable: Bool) {
        meetingLinkEnabled = enable
    }

    @MainActor
    private func hideSpinner() {
        router.hideSpinner()
    }
    
    @MainActor
    private func showSpinner() {
        router.showSpinner()
    }
    
    @MainActor
    private func dismiss() async {
        await router.dismiss(animated: true)
    }
    
    @MainActor
    private func showSuccess(message: String) async {
        await router.showSuccess(message: message)
    }
    
    @MainActor
    private func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        router.showMeetingInfo(for: scheduledMeeting)
    }
}
