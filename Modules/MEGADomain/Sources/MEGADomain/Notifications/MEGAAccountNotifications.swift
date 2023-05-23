import Foundation

public extension Notification.Name {
    static let accountDidLogin = Notification.Name("nz.mega.login")
    static let accountDidLogout = Notification.Name("nz.mega.logout")
    static let accountEmailDidChange = Notification.Name("nz.mega.emailHasChanged")
    static let accountDidFinishFetchNodes = Notification.Name("nz.mega.fetchNodesFinished")
}
