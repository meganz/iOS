import Foundation

struct UserAlert {

    var identifier: UInt

    var isSeen: Bool

    var isRelevant: Bool

    var alertType: AlertType?

    var alertTypeString: String

    var userHandle: HandleEntity?

    var nodeHandle: HandleEntity?

    var email: String?

    var path: String?

    var name: String?

    var heading: String?

    var title: String?

    var isOwnChange: Bool

    enum AlertType: Int {
        case incomingPendingContactRequest              = 0
        case incomingPendingContactCancelled
        case incomingPendingContactReminder
        case contactChangeDeletedYou
        case contactChangeContactEstablished
        case contactChangeAccountDeleted
        case contactChangeBlockedYou
        case updatePendingContactIncomingIgnored
        case updatePendingContactIncomingAccepted
        case updatePendingContactIncomingDenied
        case updatePendingContactOutgoingAccepted
        case updatePendingContactOutgoingDenied
        case newShare
        case deletedShare
        case newShareNodes
        case removedSharesNodes
        case paymentSucceeded
        case paymentFailed
        case paymentReminder
        case takedown
        case takedownReinstated
        case total
    }
}

extension UserAlert {

    init(withMEGAAlert alert: MEGAUserAlert) {
        self.identifier = alert.identifier
        self.isSeen = alert.isSeen
        self.isRelevant = alert.isRelevant
        self.alertTypeString = alert.typeString
        self.alertType = AlertType(rawValue: alert.type.rawValue)
        self.userHandle = alert.userHandle
        self.nodeHandle = alert.nodeHandle
        self.email = alert.email
        self.path = alert.path
        self.name = alert.name
        self.heading = alert.heading
        self.title = alert.title
        self.isOwnChange = alert.isOwnChange
    }
}
