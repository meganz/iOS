// Router protocol to handle the navigation logic outside of Home module
@MainActor
public protocol HomeViewRouting {
    func route(to type: HomeWidgetRouteType)
    func openOfflineFile(base64Handle: String)
    func openNode(base64Handle: String)
}
