import Foundation

public extension Notification.Name {
    static let accountDidLogin = Notification.Name("nz.mega.login")
    static let accountDidLogout = Notification.Name("nz.mega.logout")
    static let accountEmailDidChange = Notification.Name("nz.mega.emailHasChanged")
    static let accountDidFinishFetchNodes = Notification.Name("nz.mega.fetchNodesFinished")
    static let accountDidFinishFetchAccountDetails = Notification.Name("nz.mega.fetchAccountDetailsFinished")
    static let setShouldRefreshAccountDetails = Notification.Name("nz.mega.setShouldRefreshAccountDetails")
    static let refreshAccountDetails = Notification.Name("nz.mega.refreshAccountDetails")
    static let accountDidPurchasedPlan = Notification.Name("nz.mega.accountDidPurchasedPlan")
    static let sortingPreferenceChanged = Notification.Name("MEGASortingPreference")
    static let dismissOnboardingProPlanDialog = Notification.Name("nz.mega.dismissOnboardingProPlanDialog")
    static let storageStatusDidChange = Notification.Name("nz.mega.storageStatusDidChange")
    static let storageEventDidChange = Notification.Name("nz.mega.event.storage")
    static let startAds = Notification.Name("nz.mega.startAds")
}

public enum NotificationUserInfoKey {
    public static let storageEventState = "nz.mega.event.storage.stateKey"
}
