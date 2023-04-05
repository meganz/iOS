import MEGADomain

protocol ScheduleMeetingRouting {
    func discardChanges()
    func showAddParticipants(alreadySelectedUsers: [UserEntity], newSelectedUsers: @escaping (([UserEntity]?) -> Void))
}

final class ScheduleMeetingViewModel: ObservableObject {
    
    private enum Constants {
        static let meetingNameMaxLenght: Int = 30
        static let meetingDescriptionMaxLenght: Int = 4000
        static let minDurationFiveMinutes: TimeInterval = 300
        static let defaultDurationHalfHour: TimeInterval = 1800
    }
    
    private let router: ScheduleMeetingRouting

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

    let timeFormatter = DateFormatter.timeShort()
    let dateFormatter = DateFormatter.dateMedium()
    
    private var participants = [UserEntity]() {
        didSet {
            participantsCount = participants.count
        }
    }
    @Published var participantsCount = 0 

    init(router: ScheduleMeetingRouting) {
        self.router = router
        self.startDate = nextDateMinutesIsFiveMultiple(startDate)
        self.endDate = startDate.addingTimeInterval(Constants.defaultDurationHalfHour)
    }
    
    //MARK: - Public
    func startsDidTap() {
        startDatePickerVisible.toggle()
    }
    
    func endsDidTap() {
        endDatePickerVisible.toggle()
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
    
    //MARK: - Private
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
    }
}

