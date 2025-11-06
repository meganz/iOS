import MEGADomain
import MEGAL10n
@testable import Video
import XCTest

final class RecentlyWatchedVideosSorterTests: XCTestCase {
    
    func testSortVideosByDay_withEmptyItems_returnsEmptySection() {
        let videos: [RecentlyOpenedNodeEntity] = []
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertTrue(sortedSections.isEmpty, "Expected no sections when input is empty")
    }
    
    func testSortVideosByDay_withSingleItem_returnsSingleSection() {
        let videos = [
            anyVideo(handle: 1, daysAgo: 0)
        ]
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertEqual(sortedSections.count, 1, "Expected one section")
        XCTAssertEqual(sortedSections.first?.title, todayTitle, "Expected section title to be 'Today'")
        XCTAssertEqual(sortedSections.first?.videos.count, 1, "Expected one video in the section")
    }
    
    func testSortVideosByDay_withTwoItemsSameDate_returnsSingleSection() {
        let videos = [
            anyVideo(handle: 1, daysAgo: 0),
            anyVideo(handle: 2, daysAgo: 0)
        ]
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertEqual(sortedSections.count, 1, "Expected one section")
        XCTAssertEqual(sortedSections.first?.title, todayTitle, "Expected section title to be 'Today'")
        XCTAssertEqual(sortedSections.first?.videos.count, 2, "Expected two video in the section")
    }
    
    func testSortVideosByDay_withTwoItemsSameDayDifferentTime_returnsSingleSection() {
        let calendar = Calendar(identifier: .gregorian)
        let firstWatchedVideo = anyVideo(handle: 2, hourAgo: 4, respectiveToDate: customTestSpecificDate(using: calendar).date, calendar: calendar)
        let latestWatchedVideo = anyVideo(handle: 1, hourAgo: 1, respectiveToDate: customTestSpecificDate(using: calendar).date, calendar: calendar)
        let videos = [
            firstWatchedVideo,
            latestWatchedVideo
        ]
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertEqual(sortedSections.count, 1, "Expected one section")
        let dateInString = customTestSpecificDate(using: calendar).dateInString
        XCTAssertEqual(sortedSections.first?.title, dateInString, "Expected section title to be 'Sat, Sep 30, 2023'")
        XCTAssertEqual(sortedSections.first?.videos.count, 2, "Expected two video in the section")
        let retrievedVideos = sortedSections.first?.videos.map(\.node.handle)
        XCTAssertEqual(retrievedVideos, [
            latestWatchedVideo.node.handle,
            firstWatchedVideo.node.handle
        ])
    }
    
    func testSortVideosByDay_withTwoItemsWithDifferentDay_returnsTwoSections() {
        let videos = [
            anyVideo(handle: 1, daysAgo: 0), // Today
            anyVideo(handle: 2, daysAgo: 1)  // Yesterday
        ]
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertEqual(sortedSections.count, 2, "Expected two sections")
        XCTAssertEqual(sortedSections[0].title, todayTitle, "Expected first section title to be 'Today'")
        XCTAssertEqual(sortedSections[1].title, yesterdayTitle, "Expected second section title to be 'Yesterday'")
        XCTAssertEqual(sortedSections[0].videos.count, 1, "Expected one video in the 'Today' section")
        XCTAssertEqual(sortedSections[1].videos.count, 1, "Expected one video in the 'Yesterday' section")
    }
    
    func testSortVideosByDay_withThreeItemsWithDifferentDay_returnsThreeSections() {
        let videos = [
            anyVideo(handle: 1, daysAgo: 0), // Today
            anyVideo(handle: 2, daysAgo: 1), // Yesterday
            anyVideo(handle: 3, daysAgo: 2)  // 2 days ago
        ]
        let sortedSections = sortVideosByDay(videos: videos)
        
        XCTAssertEqual(sortedSections.count, 3, "Expected three sections")
        XCTAssertEqual(sortedSections[0].title, todayTitle, "Expected first section title to be 'Today'")
        XCTAssertEqual(sortedSections[1].title, yesterdayTitle, "Expected second section title to be 'Yesterday'")
        XCTAssertEqual(sortedSections[0].videos.count, 1, "Expected one video in the 'Today' section")
        XCTAssertEqual(sortedSections[1].videos.count, 1, "Expected one video in the 'Yesterday' section")
        XCTAssertEqual(sortedSections[2].videos.count, 1, "Expected one video in the 'Day name, Day Month Year' section")
    }
    
    // MARK: - Helpers
    
    private func anyVideo(handle: Int, daysAgo: Int = 0, hourAgo: Int = 0, respectiveToDate date: Date = Date.now, calendar: Calendar = Calendar.current) -> RecentlyOpenedNodeEntity {
        let dayAdjustedDate = calendar.date(byAdding: .day, value: -daysAgo, to: date)!
        let finalDate = calendar.date(byAdding: .hour, value: -hourAgo, to: dayAdjustedDate)!
        return RecentlyOpenedNodeEntity(
            node: NodeEntity(name: "video-\(handle).mp4", handle: HandleEntity(handle)),
            lastOpenedDate: finalDate,
            mediaDestination: MediaDestinationEntity(fingerprint: "any-fingerprint", destination: 0, timescale: 0)
        )
    }
    
    private func customTestSpecificDate(using calendar: Calendar) -> (date: Date, dateInString: String) {
        let date = calendar.date(from: DateComponents(year: 2023, month: 10, day: 1, hour: 14, minute: 0))!
        let dateInString = "Sat, Sep 30, 2023"
        return (date, dateInString)
    }
    
    private var todayTitle: String {
        Strings.Localizable.today
    }
    
    private var yesterdayTitle: String {
        Strings.Localizable.yesterday
    }
    
    private func sortVideosByDay(videos: [RecentlyOpenedNodeEntity]) -> [RecentlyWatchedVideoSection] {
        let sut = RecentlyWatchedVideosSorter()
        return sut.sortVideosByDay(videos: videos, configuration: testDateConfiguration())
    }
    
    private func testDateConfiguration() -> RecentlyWatchedVideosSectionDateConfiguration {
        RecentlyWatchedVideosSectionDateConfiguration(
            dateFormatTemplate: "E, d MMM yyyy",
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            locale: Locale(identifier: "en-US")
        )
    }
}
