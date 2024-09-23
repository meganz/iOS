import Foundation
import MEGADomain

public struct RecentlyWatchedVideoSection: Identifiable {
    public let id = UUID()
    public let title: String
    public let videos: [RecentlyWatchedVideoEntity]
}
