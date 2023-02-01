import MEGADomain

final class ScheduledMeetingOccurrencesViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private let scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    private var occurrences: [ScheduledMeetingOccurrenceEntity] = []

    @Published var title: String
    @Published var subtitle: String?
    @Published var diplayOccurrences: [ScheduleMeetingOccurence] = []
    @Published private(set) var primaryAvatar: UIImage?
    @Published private(set) var secondaryAvatar: UIImage?
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol,
         chatRoomAvatarViewModel: ChatRoomAvatarViewModel?) {
        self.scheduledMeeting = scheduledMeeting
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatRoomAvatarViewModel = chatRoomAvatarViewModel
        
        self.title = scheduledMeeting.title
        self.primaryAvatar = chatRoomAvatarViewModel?.primaryAvatar
        self.secondaryAvatar = chatRoomAvatarViewModel?.secondaryAvatar
        updateSubtitle()
        fetchOccurrences()
    }

    //MARK: - Public
    func seeMoreTapped() {
        
    }

    //MARK: - Private
    private func updateSubtitle(){
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
                occurrences = try await scheduledMeetingUseCase.scheduledMeetingOccurrencesByChat(chatId: scheduledMeeting.chatId)
                await populateOccurrences()
            } catch {
                MEGALogError("Error fetching occurrences for scheduled meeting: \(scheduledMeeting.title)")
            }
            
        }
    }
    
    @MainActor
    private func populateOccurrences() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMM"
        let timeFormatter = DateFormatter.timeShort()
        
        diplayOccurrences = occurrences.map {
            ScheduleMeetingOccurence(
                id: UUID().uuidString,
                date: dateFormatter.localisedString(from: $0.startDate),
                title: scheduledMeeting.title,
                time: timeFormatter.localisedString(from: scheduledMeeting.startDate) + " - " + timeFormatter.localisedString(from: scheduledMeeting.endDate))
        }
    }
}
