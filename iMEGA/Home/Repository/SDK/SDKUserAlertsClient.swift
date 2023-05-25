import Foundation

struct SDKUserAlertsClient {

    var notification: () -> [UserAlert]?

    var contactRequest: () -> [ContactRequest]

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
            notification: { () -> [UserAlert]? in
                let alerts = api.userAlertList()
                return convert(alerts)
            },

            contactRequest: { () -> [ContactRequest] in
                let incomingContactRequest = api.incomingContactRequests()
                return convert(incomingContactRequest)
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

private func convert(_ megaUserAlertList: MEGAUserAlertList) -> [UserAlert] {
    return (0..<megaUserAlertList.size).compactMap { index in
        UserAlert(withMEGAAlert: megaUserAlertList.usertAlert(at: index))
    }
}

private func convert(_ megaContactRequestList: MEGAContactRequestList) -> [ContactRequest] {
    (0..<megaContactRequestList.size.intValue).compactMap { index in
        ContactRequest(from: megaContactRequestList.contactRequest(at: index))
    }
}
