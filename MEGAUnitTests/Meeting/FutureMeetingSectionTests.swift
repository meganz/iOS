@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class FutureMeetingSectionTests: XCTestCase {
    @MainActor
    func testFilter_withEmptySearchText_shouldBeNil() {
        XCTAssertNil(createFutureMeetingSection().filter(withSearchText: ""))
    }
    
    @MainActor
    func testFilter_multipleItemInSection_shouldMatch() {
        let searchTexts = [randomString(length: 4), randomString(length: 7)]
        let chatIds: [UInt64] = createdRandomChatIds(count: searchTexts.count)
        let futureMeetingSection = createFutureMeetingSection(
            withChatIds: chatIds,
            chatRoomUsersDescriptionResults: [.success(searchTexts[0]), .success(searchTexts[1])],
            dateSetList: createDateSetList(withCount: searchTexts.count)
        )
        
        let predicate = NSPredicate { _, _ in
            let filteredFutureMeetingSection = futureMeetingSection.filter(withSearchText: searchTexts[0])
            return filteredFutureMeetingSection?.items.count == 1
            && filteredFutureMeetingSection?.items.first?.scheduledMeeting.chatId == chatIds[0]
        }
        
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 10)
    }
    
    @MainActor
    func testInsert_AtFirstIndex_shouldMatch() throws {
        let day1 = try XCTUnwrap(sampleDate(withDay: 1))
        let futureMeetingRoomViewModel = FutureMeetingRoomViewModel(scheduledMeeting: ScheduledMeetingEntity(startDate: day1, endDate: day1))
        
        var futureMeetingSection = createFutureMeetingSection(withDayRange: 2...31)
        futureMeetingSection.insert(futureMeetingRoomViewModel)
        XCTAssertEqual(futureMeetingSection.items.first, futureMeetingRoomViewModel)
    }
    
    @MainActor
    func testInsert_InTheMiddle_shouldMatch() throws {
        let day1 = try XCTUnwrap(sampleDate(withDay: 14))
        let futureMeetingRoomViewModel = FutureMeetingRoomViewModel(scheduledMeeting: ScheduledMeetingEntity(startDate: day1, endDate: day1))
        
        let chatIds: [UInt64] = createdRandomChatIds(count: 4)
        var futureMeetingSection = createFutureMeetingSection(
            withChatIds: chatIds,
            chatRoomUsersDescriptionResults: createFailureResult(withCount: chatIds.count),
            dateSetList: createDateSetList(withCount: 2, dayRange: 1...10) + createDateSetList(withCount: 2, dayRange: 20...31)
        )
        futureMeetingSection.insert(futureMeetingRoomViewModel)
        XCTAssertEqual(futureMeetingSection.items[2], futureMeetingRoomViewModel)
    }
    
    @MainActor
    func testInsert_atTheEnd_shouldMatch() throws {
        let day1 = try XCTUnwrap(sampleDate(withDay: 31))
        let futureMeetingRoomViewModel = FutureMeetingRoomViewModel(scheduledMeeting: ScheduledMeetingEntity(startDate: day1, endDate: day1))
        
        var futureMeetingSection = createFutureMeetingSection(withDayRange: 1...30)
        futureMeetingSection.insert(futureMeetingRoomViewModel)
        XCTAssertEqual(futureMeetingSection.items.last, futureMeetingRoomViewModel)
    }
    
    // MARK: - Private methods
    
    @MainActor
    private func createFutureMeetingSection(withDayRange dayRange: ClosedRange<Int> = 1...31, chatIds: [UInt64]? = nil) -> FutureMeetingSection {
        let chatIds: [UInt64] = chatIds ?? createdRandomChatIds(count: Int.random(in: 1...10))
        return createFutureMeetingSection(
            withChatIds: chatIds,
            chatRoomUsersDescriptionResults: createFailureResult(withCount: chatIds.count),
            dateSetList: createDateSetList(withCount: chatIds.count, dayRange: dayRange)
        )
    }

    private func createDateSetList(withCount count: Int, dayRange: ClosedRange<Int> = 1...31) -> [(startDate: Date, endDate: Date)] {
        let dates = createSampleDates(withCount: count, dayRange: dayRange)
        return dates.map { ($0, $0)}
    }
    
    private func createSampleDates(withCount count: Int, dayRange: ClosedRange<Int> = 1...31) -> [Date] {
        let randomDays = (0...count).reduce([Int]()) { days, _ in
            var randomDay = Int.random(in: dayRange)
            while days.contains(randomDay) {
                randomDay = Int.random(in: dayRange)
            }
            return days + [randomDay]
        }
        
        return randomDays.sorted().map { sampleDate(withDay: $0) ?? Date() }
    }
    
    private func sampleDate(withDay day: Int = 16) -> Date? {
        guard day >= 1 && day <= 31 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "\(day)/05/2023")
    }
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    private func createdRandomChatIds(count: Int) -> [UInt64] {
        (1...count).map { _ in UInt64.random(in: UInt64.min...UInt64.max) }
    }
    
    private func createFailureResult(withCount count: Int) -> [Result<String, any Error>] {
        (1...count).map { _ in Result.failure(GenericErrorEntity()) }
    }
    
    @MainActor
    private func createFutureMeetingSection(
        withChatIds chatIds: [UInt64],
        chatRoomUsersDescriptionResults: [Result<String, any Error>],
        dateSetList: [(startDate: Date, endDate: Date)]
    ) -> FutureMeetingSection {
        let items = chatIds.enumerated().map { index, chatId in
            createFutureMeetingRoomViewModel(
                withChatId: chatId,
                chatRoomUsersDescriptionResult: chatRoomUsersDescriptionResults[index],
                dateSet: dateSetList[index])
        }
        let section = FutureMeetingSection(title: "", date: Date(), items: items)
        return section
    }
    
    @MainActor
    private func createFutureMeetingRoomViewModel(
        withChatId chatId: UInt64,
        chatRoomUsersDescriptionResult: Result<String, any Error>,
        dateSet: (startDate: Date, endDate: Date)
    ) -> FutureMeetingRoomViewModel {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: chatId))
        let chatRoomUserUseCase = MockChatRoomUserUseCase(chatRoomUsersDescriptionResult: chatRoomUsersDescriptionResult)
        return FutureMeetingRoomViewModel(
            scheduledMeeting: ScheduledMeetingEntity(chatId: chatId, startDate: dateSet.startDate, endDate: dateSet.endDate),
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase
        )
    }
}
