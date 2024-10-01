@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ScheduledMeetingDateBuilderTests: XCTestCase {
    
    func testBuildDateDescriptionString_givenWeeklyFrequencyAndOccursEveryDay_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:45"))
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, interval: 1, weekDayList: Array(1...7))
        let scheduleMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate, rules: rules)
        let builder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduleMeeting)
        let description = builder.buildDateDescriptionString(removingFormatter: .all, locale: Locale(identifier: "en_GB"))
        
        XCTAssert(
             description == "Every day effective 22 Jun 2023 from 10:30 AM to 10:45 AM" ||
             description == "Every day effective 22 Jun 2023 from 10:30 to 10:45"
        )
    }
    
    func testBuildDateDescriptionString_givenWeeklyFrequencyAndOccursEveryDayAlternateWeek_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:45"))
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, interval: 2, weekDayList: Array(1...7))
        let scheduleMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate, rules: rules)
        let builder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduleMeeting)
        let description = builder.buildDateDescriptionString(removingFormatter: .all, locale: Locale(identifier: "en_GB"))
        
        XCTAssert(
             description == "Mon, Tue, Wed, Thu, Fri, Sat and Sun every 2 weeks effective 22 Jun 2023 from 10:30 AM to 10:45 AM" ||
             description == "Mon, Tue, Wed, Thu, Fri, Sat and Sun every 2 weeks effective 22 Jun 2023 from 10:30 to 10:45"
        )
    }
    
    func testBuildDateDescriptionString_givenWeeklyFrequencyOnThursday_shouldMatch() throws {
        let startDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:30"))
        let endDate = try XCTUnwrap(sampleDate(from: "22/06/2023 10:45"))
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, interval: 1, weekDayList: [4])
        let scheduleMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate, rules: rules)
        let builder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduleMeeting)
        let description = builder.buildDateDescriptionString(removingFormatter: .all, locale: Locale(identifier: "en_GB"))
        
        XCTAssert(
             description == "Thu every week effective 22 Jun 2023 from 10:30 AM to 10:45 AM" ||
             description == "Thu every week effective 22 Jun 2023 from 10:30 to 10:45"
        )
    }
    
    // MARK: - Private methods.
    
    private func sampleDate(from string: String = "12/06/2023 09:10") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.date(from: string)
    }
}
