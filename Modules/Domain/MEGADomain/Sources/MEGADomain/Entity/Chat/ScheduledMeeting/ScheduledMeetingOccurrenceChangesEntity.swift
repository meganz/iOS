import Foundation

public struct ScheduledMeetingOccurrenceChangesEntity {
    public let startDate: Date?
    public let endDate: Date?
    public let cancelled: Bool?
    
    public init(startDate: Date? = nil, endDate: Date? = nil, cancelled: Bool? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.cancelled = cancelled
    }
}
