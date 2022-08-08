import Foundation
import MEGADomain

struct UserSDKEntity {

    /// The email associated with the contact.
    let email: String

    /// The handle associated with the contact.
    let handle: HandleEntity

    /// The base64Handle associated with the contact.
    let base64Handle: Base64HandleEntity?

    /// If not nil, it represents the changes / updates from this user.
    let change: Change?

    /// If this user is a contact, this filed contains the contact related information.
    let contact: Contact?

    struct Change {

        let changeType: ChangeType

        let changeOrigin: ChangeOrigin

        init?(change: MEGAUserChangeType, changeOrigin: Int) {
            guard let changeType = ChangeType(rawValue: change.rawValue) else {
                return nil
            }
            self.changeType = changeType
            self.changeOrigin = ChangeOrigin(withChangeOriginNumber: changeOrigin)
        }

        /// A bit field with the changes of the user
        enum ChangeType: Int {
            case auth                    = 0x01
            case lstint                  = 0x02
            case avatar                  = 0x04
            case firstname               = 0x08
            case lastname                = 0x10
            case email                   = 0x20
            case keyring                 = 0x40
            case country                 = 0x80
            case birthday                = 0x100
            case pubKeyCu255             = 0x200
            case pubKeyEd255             = 0x400
            case sigPubKeyRsa            = 0x800
            case sigPubKeyCu255          = 0x1000
            case language                = 0x2000
            case pwdReminder             = 0x4000
            case disableVersions         = 0x8000
            case contactLinkVerification = 0x10000
            case richPreviews            = 0x20000
            case rubbishTime             = 0x40000
            case storageState            = 0x80000
            case geolocation             = 0x100000
            case cameraUploadsFolder     = 0x200000
            case myChatFilesFolder       = 0x400000
            case pushSettings            = 0x800000
            case userAlias               = 0x1000000
        }

        enum ChangeOrigin {
            case external
            case explicit
            case implicit

            init(withChangeOriginNumber changeOriginNumber: Int) {
                if changeOriginNumber == 0 {
                    self = .external
                } else if changeOriginNumber > 0 {
                    self = .explicit
                } else {
                    self = .implicit
                }
            }
        }
    }

    struct Contact {

        let timeAddedToContact: Date

        let contactVisibility: Visibility

        init?(withBecomingContactDate becomingContactDate: Date, contactVisibility: MEGAUserVisibility) {
            guard let visibility = Visibility(rawValue: contactVisibility.rawValue) else { return nil }
            self.contactVisibility = visibility
            self.timeAddedToContact = becomingContactDate
        }

        enum Visibility: Int {
            case unknown  = -1
            case hidden   = 0
            case visible  = 1
            case inactive = 2
            case blocked  = 3
        }
    }
}

extension UserSDKEntity {

    init(with megaUser: MEGAUser, base64Handle: Base64HandleEntity?) {
        self.email = megaUser.email
        self.handle = megaUser.handle
        self.base64Handle = base64Handle
        self.change = Change(
            change: megaUser.changes,
            changeOrigin: megaUser.isOwnChange
        )
        self.contact = Contact(
            withBecomingContactDate: megaUser.timestamp,
            contactVisibility: megaUser.visibility
        )
    }
}
