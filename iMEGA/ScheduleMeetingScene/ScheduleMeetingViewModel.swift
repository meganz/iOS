import Combine
import MEGAAnalyticsiOS
import MEGAAssets
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAPresentation
import SwiftUI

@MainActor
final class ScheduleMeetingViewModel: ObservableObject {
    
    enum Constants {
        static let meetingNameMaxLength: Int = 30
        static let meetingDescriptionMaxLength: Int = 3000
        static let minDurationFiveMinutes: TimeInterval = 300
        static let freePlanDurationLimit: TimeInterval = 3600
    }
    
    var title: String { viewConfiguration.title }
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
    var shouldAllowEditingWaitingRoom: Bool { viewConfiguration.shouldAllowEditingWaitingRoom }
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { viewConfiguration.shouldAllowEditingAllowNonHostsToAddParticipants }
    var shouldAllowEditingMeetingDescription: Bool { viewConfiguration.shouldAllowEditingMeetingDescription }
    
    @Published var startDate: Date {
        didSet {
            startDateUpdated(previouslySelectedDate: oldValue)
            updateRightBarButtonState()
            showLimitDurationViewIfNeeded()
        }
    }
    
    @Published var endDate: Date {
        didSet {
            endDateFormatted = formatDate(endDate)
            updateRightBarButtonState()
            showLimitDurationViewIfNeeded()
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
    
    @Published var meetingLinkEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }
    
    @Published var calendarInviteEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }
    
    @Published var waitingRoomEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }
    
    @Published var allowNonHostsToAddParticipantsEnabled: Bool {
        didSet { updateRightBarButtonState() }
    }

    @Published var showWaitingRoomWarningBanner = false
    @Published var meetingNameTooLong = false
    @Published var startDatePickerVisible = false
    @Published var endDatePickerVisible = false
    @Published var meetingDescriptionTooLong = false
    @Published var meetingLinkToggleUIEnabled = true
    @Published var showDiscardAlert = false
    @Published var isRightBarButtonEnabled = false
    @Published var participantHandleList: [HandleEntity] = []
    @Published var showLimitDurationView = false

    @PreferenceWrapper(key: .waitingRoomWarningBannerDismissed, defaultValue: false)
    var waitingRoomWarningBannerDismissed: Bool
    
    var monthlyRecurrenceFootnoteViewText: String? {
        guard rules.frequency == .monthly, let day = rules.monthDayList?.first else { return nil }
        
        switch day {
        case 29, 30, 31:
            return Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(day)
        default:
            return nil
        }
    }
    
    @Published private(set) var rules: ScheduledMeetingRulesEntity

    private let router: any ScheduleMeetingRouting
    private let viewConfiguration: any ScheduleMeetingViewConfigurable
    private let accountUseCase: any AccountUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private var chatMonetisationEnabled = false
    private var subscriptions = Set<AnyCancellable>()
    private let shareLinkHandler: (ShareLinkRequestData) -> Void
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    init(
        router: some ScheduleMeetingRouting,
        viewConfiguration: some ScheduleMeetingViewConfigurable,
        accountUseCase: some AccountUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        shareLinkHandler: @escaping (ShareLinkRequestData) -> Void
    ) {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.viewConfiguration = viewConfiguration
        self.accountUseCase = accountUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.tracker = tracker
        self.shareLinkHandler = shareLinkHandler
        self.meetingName = viewConfiguration.meetingName
        self.meetingDescription = viewConfiguration.meetingDescription
        self.startDate = viewConfiguration.startDate
        self.endDate = viewConfiguration.endDate
        self.calendarInviteEnabled = viewConfiguration.calendarInviteEnabled
        self.waitingRoomEnabled = viewConfiguration.waitingRoomEnabled
        self.allowNonHostsToAddParticipantsEnabled = viewConfiguration.allowNonHostsToAddParticipantsEnabled
        self.meetingLinkEnabled = viewConfiguration.meetingLinkEnabled
        self.rules = viewConfiguration.rules
        self.participantHandleList = viewConfiguration.participantHandleList
        $waitingRoomWarningBannerDismissed.useCase = preferenceUseCase
        updateMeetingLinkToggle()
        initShowWarningBannerSubscription()
    }
    
    func viewAppeared() async {
        // [MEET-3932] as part of migration from local, synchronous feature flags system,
        // to server backed, remote async system, we read and cache the value
        // when view appears to avoid rewriting too much inside the view model itself
        await loadAndCacheFeatureFlagValue()
        updateRightBarButtonState()
        showLimitDurationViewIfNeeded()
        tracker.trackAnalyticsEvent(with: viewConfiguration.trackingEvents.screenEvent)
    }
    
    func loadAndCacheFeatureFlagValue() async {
        chatMonetisationEnabled = await remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .chatMonetisation)
    }
    
    // MARK: - Public
    func submitButtonTapped() async {
        if isNewMeeting {
            tracker.trackAnalyticsEvent(with: ScheduledMeetingCreateConfirmButtonEvent())
        }
        
        do {
            showSpinner()
            let scheduleMeetingProxy = makeScheduleMeetingProxyEntity()
            let completion = try await viewConfiguration.submit(meeting: scheduleMeetingProxy)
            hideSpinner()
            await dismiss()
            handle(completion: completion, linkEnabled: meetingLinkEnabled)
        } catch {
            MEGALogError("Unable to submit with error \(error)")
            hideSpinner()
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
    
    func cancelDidTap() async {
        guard !areDetailsUnchanged() else {
            await dismiss()
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
            self.updateRightBarButtonState()
        }
    }
    
    func showRecurrenceOptionsView() {
        tracker.trackAnalyticsEvent(with: ScheduledMeetingSettingRecurrenceButtonEvent())
        router
            .showRecurrenceOptionsView(rules: rules, startDate: startDate)?
            .assign(to: &$rules)
    }
    
    func upgradePlansViewTapped() {
        guard let accountDetails = accountUseCase.currentAccountDetails else { return }
        router.showUpgradeAccount(accountDetails)
        tracker.trackAnalyticsEvent(with: viewConfiguration.upgradeButtonTappedEvent)
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
        isRightBarButtonEnabled = !areDetailsUnchanged()
        && !meetingNameTooLong
        && !meetingDescriptionTooLong
        && !trimmedMeetingName.isEmpty
    }
    
    func onMeetingLinkEnabledChange(_ enabled: Bool) {
        guard enabled else { return }
        tracker.trackAnalyticsEvent(with: viewConfiguration.trackingEvents.meetingLinkEnabled)
    }
    
    func onCalendarInviteEnabledChange(_ enabled: Bool) {
        guard enabled else { return }
        tracker.trackAnalyticsEvent(with: ScheduledMeetingSettingSendCalendarInviteButtonEvent())
    }
    
    func onWaitingRoomEnabledChange(_ enabled: Bool) {
        guard enabled else { return }
        tracker.trackAnalyticsEvent(with: WaitingRoomEnableButtonEvent())
    }
    
    func onAllowNonHostsToAddParticipantsEnabledChange(_ enabled: Bool) {
        guard enabled else { return }
        tracker.trackAnalyticsEvent(with: ScheduledMeetingSettingEnableOpenInviteButtonEvent())
    }
    
    func showLimitDurationViewIfNeeded() {
        showLimitDurationView = shouldShowFreePlanLimit()
    }
    
    // MARK: - Private
    
    private func initShowWarningBannerSubscription() {
        Publishers.CombineLatest($waitingRoomEnabled, $allowNonHostsToAddParticipantsEnabled)
            .dropFirst(waitingRoomWarningBannerDismissed ? 1 : 0)
            .map { $0 && $1 }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] show in
                guard let self else { return }
                withAnimation {
                    self.showWaitingRoomWarningBanner = show
                }
                if show {
                    waitingRoomWarningBannerDismissed = false
                }
            })
            .store(in: &subscriptions)
    }

    private func updated(occurrence: ScheduledMeetingOccurrenceEntity) {
        router.updated(occurrence: occurrence)
    }
    
    private func updated(meeting: ScheduledMeetingEntity) {
        router.updated(meeting: meeting)
    }
    
    private func handle(
        completion: ScheduleMeetingViewConfigurationCompletion,
        linkEnabled: Bool
    ) {
        switch completion {
        case .showMessageForScheduleMeeting(let message, let scheduledMeeting):
            if meetingLinkEnabled {
                showModalShareLinkDialog(scheduledMeeting)
            }
            updated(meeting: scheduledMeeting)
            showSuccess(message: message)
        case .showMessageForOccurrence(let message, let occurrence, let parent):
            if meetingLinkEnabled {
                showModalShareLinkDialog(parent)
            }
            updated(occurrence: occurrence)
            showSuccess(message: message)
        case .showMessageAndNavigateToInfo(let message, let scheduledMeeting):
            if meetingLinkEnabled {
                showModalShareLinkDialog(scheduledMeeting)
            } else {
                showMeetingInfo(for: scheduledMeeting)
            }
            showSuccess(message: message)
        }
    }
    
    private func showModalShareLinkDialog(_ scheduledMeeting: ScheduledMeetingEntity) {
        let subtitle = ScheduledMeetingDateBuilder(
            scheduledMeeting: scheduledMeeting,
            chatRoom: chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId)
        ).buildDateDescriptionString()
        
        shareLinkHandler(
            .init(
                chatId: scheduledMeeting.chatId,
                title: scheduledMeeting.title,
                subtitle: subtitle,
                username: chatUseCase.myFullName() ?? ""
            )
        )
    }
    
    private func makeScheduleMeetingProxyEntity() -> ScheduleMeetingProxyEntity {
        ScheduleMeetingProxyEntity(
            title: trimmedMeetingName,
            description: trimmedMeetingDescription,
            participantHandleList: participantHandleList,
            meetingLinkEnabled: meetingLinkEnabled,
            calendarInvite: calendarInviteEnabled,
            waitingRoom: waitingRoomEnabled,
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
            meetingLinkToggleUI(enable: false)
            await viewConfiguration.updateMeetingLinkEnabled()
            meetingLink(enable: viewConfiguration.meetingLinkEnabled)
            meetingLinkToggleUI(enable: true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        dateFormatter.localisedString(from: date) + " " + timeFormatter.localisedString(from: date)
    }
    
    private func isMeetingDescriptionUnchanged() -> Bool {
        trimmedMeetingDescription == viewConfiguration.meetingDescription
        || !viewConfiguration.shouldAllowEditingMeetingDescription
    }
    
    private func isAllowNonHostsToAddParticipantsOptionUnchanged() -> Bool {
        allowNonHostsToAddParticipantsEnabled == viewConfiguration.allowNonHostsToAddParticipantsEnabled
        || !viewConfiguration.shouldAllowEditingAllowNonHostsToAddParticipants
    }
    
    private func isWaitingRoomOptionUnchanged() -> Bool {
        waitingRoomEnabled == viewConfiguration.waitingRoomEnabled
        || !viewConfiguration.shouldAllowEditingWaitingRoom
    }
    
    private func isCalendarInviteOptionUnchanged() -> Bool {
        calendarInviteEnabled == viewConfiguration.calendarInviteEnabled
        || !viewConfiguration.shouldAllowEditingCalendarInvite
    }
    
    private func isParticipantListUnchanged() -> Bool {
        participantHandleList.count == viewConfiguration.participantHandleList.count
        || !viewConfiguration.shouldAllowEditingParticipants
    }
    
    private func isMeetingLinkOptionUnchanged() -> Bool {
        meetingLinkEnabled == viewConfiguration.meetingLinkEnabled
        || !viewConfiguration.shouldAllowEditingMeetingLink
    }
    
    private func areRulesUnchanged() -> Bool {
        rules == viewConfiguration.rules
        || !viewConfiguration.shouldAllowEditingRecurrenceOption
    }
    
    private func isEndDateUnchanged() -> Bool {
        endDate == viewConfiguration.endDate
    }
    
    private func isStartDateUnchanged() -> Bool {
        startDate == viewConfiguration.startDate
    }
    
    private func isMeetingNameUnchanged() -> Bool {
        trimmedMeetingName == viewConfiguration.meetingName
        || !viewConfiguration.shouldAllowEditingMeetingName
    }
    
    private func isMeetingTimeUnchanged() -> Bool {
        isStartDateUnchanged()
        && isEndDateUnchanged()
        && areRulesUnchanged()
    }
    
    private func isMeetingAttributesUnchanged() -> Bool {
        isMeetingLinkOptionUnchanged()
        && isParticipantListUnchanged()
        && isCalendarInviteOptionUnchanged()
        && isWaitingRoomOptionUnchanged()
        && isAllowNonHostsToAddParticipantsOptionUnchanged()
    }
    
    private func isMeetingNameOrDescriptionUnchanged() -> Bool {
        isMeetingNameUnchanged() && isMeetingDescriptionUnchanged()
    }
    
    private func areDetailsUnchanged() -> Bool {
        isMeetingNameOrDescriptionUnchanged()
        && isMeetingTimeUnchanged()
        && isMeetingAttributesUnchanged()
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
    
    private func shouldShowFreePlanLimit() -> Bool {
       let freeAccountUser = accountUseCase.currentAccountDetails?.proLevel == .free
       let meetingLongerThanFreePlanLimit = endDate.timeIntervalSince(startDate) > Constants.freePlanDurationLimit
       
       return chatMonetisationEnabled && freeAccountUser && meetingLongerThanFreePlanLimit
    }
    
    private func meetingLinkToggleUI(enable: Bool) {
        meetingLinkToggleUIEnabled = enable
    }
    
    private func meetingLink(enable: Bool) {
        meetingLinkEnabled = enable
    }

    private func hideSpinner() {
        router.hideSpinner()
    }
    
    private func showSpinner() {
        router.showSpinner()
    }
    
    private func dismiss() async {
        await router.dismiss(animated: true)
    }
    
    private func showSuccess(message: String) {
        router.showSuccess(message: message)
    }

    private func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        router.showMeetingInfo(for: scheduledMeeting)
    }
    
    func scheduleMeetingBannerDismissed() {
        showWaitingRoomWarningBanner = false
        waitingRoomWarningBannerDismissed = true
    }
}
