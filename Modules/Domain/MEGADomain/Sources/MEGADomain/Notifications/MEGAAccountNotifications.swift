import Foundation

public extension Notification.Name {
    static let accountDidLogin = Notification.Name("nz.mega.login")
    static let accountDidLogout = Notification.Name("nz.mega.logout")
    static let accountEmailDidChange = Notification.Name("nz.mega.emailHasChanged")
    static let accountDidFinishFetchNodes = Notification.Name("nz.mega.fetchNodesFinished")
    static let accountDidFinishFetchAccountDetails = Notification.Name("nz.mega.fetchAccountDetailsFinished")
    static let setShouldRefreshAccountDetails = Notification.Name("nz.mega.setShouldRefreshAccountDetails")
}
