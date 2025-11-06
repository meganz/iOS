import MEGADomain
import XCTest

extension XCTestCase {
    
    private var timeZone: TimeZone {
        TimeZone(secondsFromGMT: 0)!
    }
    
    var yesterdayPlaylist: VideoPlaylistEntity {
        videoPlaylist(id: 3, creationTime: .now.daysAgo(1, timeZone: timeZone)!, modificationDate: Date())
    }
    
    var aWeekAgoPlaylist: VideoPlaylistEntity {
        videoPlaylist(id: 2, creationTime: .now.daysAgo(7, timeZone: timeZone)!, modificationDate: Date())
    }
    
    var aMonthAgoPlaylist: VideoPlaylistEntity {
        videoPlaylist(id: 1, creationTime: .now.daysAgo(30, timeZone: timeZone)!, modificationDate: Date())
    }
    
    private func videoPlaylist(id: SetHandleEntity, creationTime: Date, modificationDate: Date) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: id),
            name: "name-\(id)",
            coverNode: nil,
            count: 0,
            type: .favourite,
            creationTime: creationTime,
            modificationTime: modificationDate
        )
    }
    
    var yesterdayDate: Date {
        Date.now.daysAgo(1, timeZone: timeZone)!
    }
    
    var aWeekAgoDate: Date {
        Date.now.daysAgo(7, timeZone: timeZone)!
    }
    
    var aMonthAgoDate: Date {
        Date.now.daysAgo(10, timeZone: timeZone)!
    }
}
