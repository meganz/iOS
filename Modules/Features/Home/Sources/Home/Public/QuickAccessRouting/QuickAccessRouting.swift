public enum QuickAccessRoute: Hashable {
    case recents
    case offlines
    case offlineFile(_ base64Handle: String)
    case favourites
    case favouriteNode(_ base64Handle: String)
}

@MainActor
public protocol QuickAccessRouting {
    func handle(quickAccessRoute: QuickAccessRoute)
}
