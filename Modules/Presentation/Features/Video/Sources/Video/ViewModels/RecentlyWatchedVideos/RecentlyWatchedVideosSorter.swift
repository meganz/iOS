import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n

protocol RecentlyWatchedVideosSorterProtocol: Sendable {
    func sortVideosByDay(
        videos: [RecentlyOpenedNodeEntity],
        configuration: RecentlyWatchedVideosSectionDateConfiguration
    ) -> [RecentlyWatchedVideoSection]
}

extension RecentlyWatchedVideosSorterProtocol {
    func sortVideosByDay(
        videos: [RecentlyOpenedNodeEntity],
        configuration: RecentlyWatchedVideosSectionDateConfiguration = RecentlyWatchedVideosSectionDateConfiguration()
    ) -> [RecentlyWatchedVideoSection] {
        self.sortVideosByDay(videos: videos, configuration: configuration)
    }
}

struct RecentlyWatchedVideosSorter: RecentlyWatchedVideosSorterProtocol {
    
    func sortVideosByDay(
        videos: [RecentlyOpenedNodeEntity],
        configuration: RecentlyWatchedVideosSectionDateConfiguration = RecentlyWatchedVideosSectionDateConfiguration()
    ) -> [RecentlyWatchedVideoSection] {
        let calendar = configuration.calendar
        let today = calendar.startOfDay(for: Date.now)
        let yesterday = yesterdayDate(from: calendar)
        
        let groupedVideos = Dictionary(grouping: videos) { video in
            let startOfDay = calendar.startOfDay(for: video.lastOpenedDate ?? Date())
            if startOfDay == today {
                return today
            } else if startOfDay == yesterday {
                return yesterday
            } else {
                return startOfDay
            }
        }
        
        return groupedVideos
            .map { (date, videos) -> RecentlyWatchedVideoSection in
                let title = if date == today {
                    Strings.Localizable.today
                } else if date == yesterday {
                    Strings.Localizable.yesterday
                } else {
                    DateFormatter
                        .fromTemplate(
                            "E, d MMM yyyy",
                            calendar: configuration.calendar,
                            timeZone: configuration.timeZone,
                            locale: configuration.locale
                        )
                        .localisedString(from: date)
                }
                return RecentlyWatchedVideoSection(title: title, videos: videos)
            }
            .sorted { $0.videos.first?.lastOpenedDate ?? Date.now > $1.videos.first?.lastOpenedDate ?? Date.now }
    }
    
    private func yesterdayDate(from calendar: Calendar) -> Date {
        guard let date = calendar.date(byAdding: .day, value: -1, to: Date.now) else {
            return Date.now
        }
        return calendar.startOfDay(for: date)
    }
}
