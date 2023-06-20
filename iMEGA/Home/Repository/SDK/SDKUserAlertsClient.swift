import Foundation
import MEGADomain

struct SDKUserAlertsClient {

    var notification: () -> [UserAlertEntity]?

    var contactRequest: () -> [ContactRequestEntity]

    var userAlertsUpdate: (
        _ alertsUpdateNotifier: @escaping () -> Void
    ) -> Void

    var incomingContactRequestUpdate: (
        _ contactRequestUpdateNotifier: @escaping () -> Void
    ) -> Void

    var cleanup: () -> Void
}

extension SDKUserAlertsClient {

    static var live: Self {
        let api = MEGASdkManager.sharedMEGASdk()
        let globalUserAlertsAndContactRequestDelegate = MEGAUserNotificationGlobalDelegate()
        api.add(globalUserAlertsAndContactRequestDelegate)

        return Self(
            notification: { () -> [UserAlertEntity]? in
                let alerts = api.userAlertList()
                return alerts.toUserAlertEntities()
            },

            contactRequest: { () -> [ContactRequestEntity] in
                let incomingContactRequest = api.incomingContactRequests()
                return incomingContactRequest.toContactRequestEntities()
            },

            userAlertsUpdate: { alertsNotifier in
                globalUserAlertsAndContactRequestDelegate.onUserAlertsUpdateCallback = alertsNotifier
            },

            incomingContactRequestUpdate: { contactRequestNotifier in
                globalUserAlertsAndContactRequestDelegate.onUserIncomingContactRequestCallback = contactRequestNotifier
            },

            cleanup: {
                api.remove(globalUserAlertsAndContactRequestDelegate)
            }
        )
    }

    final class MEGAUserNotificationGlobalDelegate: NSObject, MEGAGlobalDelegate {

        var onUserAlertsUpdateCallback: (() -> Void)?

        var onUserIncomingContactRequestCallback: (() -> Void)?

        func onUserAlertsUpdate(_ api: MEGASdk, userAlertList: MEGAUserAlertList) {
            onUserAlertsUpdateCallback?()
        }

        func onContactRequestsUpdate(_ api: MEGASdk, contactRequestList: MEGAContactRequestList) {
            onUserIncomingContactRequestCallback?()
        }
    }
}
