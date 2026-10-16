import Home

@MainActor
final class SpyHomeViewRouter: HomeViewRouting {
    private(set) var routes: [HomeWidgetRouteType] = []

    var isOverDiskQuotaRouted: Bool {
        routes.contains {
            if case .overDiskQuota = $0 { return true }
            return false
        }
    }

    var openedAlbumNames: [String] {
        routes.compactMap {
            if case .album(let album) = $0 { return album.name }
            return nil
        }
    }

    func route(to type: HomeWidgetRouteType) {
        routes.append(type)
    }

    func openOfflineFile(base64Handle: String) {}

    func openNode(base64Handle: String) {}
}
