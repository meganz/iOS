
import Contacts

struct ContactOnMega {
    var handle = UInt64()
    var email = String()
    var name = String()

    init(handle: UInt64, email: String, name: String) {
        self.handle = handle
        self.email = email
        self.name = name
    }
}

@objc class ContactsOnMegaManager: NSObject {
    
    enum ContactsOnMegaState {
        case unknown
        case fetching
        case ready
        case error
    }
    
    var state = ContactsOnMegaState.unknown
    var contactsOnMega = [ContactOnMega]()
    var contacts = [MEGAUser]()

    var completionWhenReady : (() -> Void)?

    @objc static let shared: ContactsOnMegaManager = {
        return ContactsOnMegaManager()
    }()
    
    private override init() {}
    
    @objc func contactsOnMegaCount() -> NSInteger {
        if state == .ready {
            return contactsOnMega.count
        } else {
            return 0
        }
    }
    
    func fetchContactsOnMega() -> [ContactOnMega]? {
        if state == .ready {
            return contactsOnMega
        } else {
            return nil
        }
    }

    @objc func configureContactsOnMega(completion: (() -> Void)?) {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            guard let userContacts = MEGASdkManager.sharedMEGASdk().contacts() else  { return }
            for i in 0 ..< userContacts.size.intValue {
                guard let user = userContacts.user(at: i) else { return }
                if user.visibility == .visible {
                    contacts.append(user)
                }
            }
            
            completionWhenReady = completion
            state = .fetching
            getDeviceContacts()
        }
    }
    
    private func getDeviceContacts() {
        var deviceContacts = [[String:String]]()
        let contactsStore = CNContactStore()

        let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]

        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore.defaultContainerIdentifier())
        do {
            let phoneNumberKit = PhoneNumberKit()
            
            let contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            for contact in contacts {
                for label in contact.phoneNumbers {
                    do {
                        let phoneNumber = try phoneNumberKit.parse(label.value.stringValue)
                        let formatedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
                        let name = contact.givenName + " " + contact.familyName

                        deviceContacts.append([formatedNumber:name])

                        print(phoneNumber)
                        print(formatedNumber)
                    }
                    catch {
                        print("Device contact number parser error " + label.value.stringValue)
                    }
                }
            }
            
            print("Contacts ", deviceContacts)
            getContactsOnMega(deviceContacts)
        } catch {
            state = .error
            print("Error fetching user contacts: ", error)
        }
    }
    
    private func getContactsOnMega(_ deviceContacts: [[String:String]]) {
        let getRegisteredContactsDelegate = MEGAGetRegisteredContactsRequestDelegate.init { (request, error) in
            if error.type == .apiOk {
                for contactOnMega in request.stringTableArray {
                    let userHandle = MEGASdk.handle(forBase64UserHandle: contactOnMega[1])

                    if self.contacts.filter({$0.handle == userHandle}).count == 0 {
                        var contactName = ""
                        for deviceContact in deviceContacts {
                            if let name = deviceContact[contactOnMega[0]] {
                                contactName = name
                            }
                        }
                        let emailRequestDelegate = MEGAChatGenericRequestDelegate.init(completion: { (request, error) in
                            self.contactsOnMega.append(ContactOnMega(handle: userHandle, email: request.text, name: contactName))
                        })
                        MEGASdkManager.sharedMEGAChatSdk().userEmail(byUserHandle: userHandle, delegate: emailRequestDelegate)
                    }
                }
                self.state = .ready
                if (self.completionWhenReady != nil) {
                    self.completionWhenReady!()
                }
            } else {
                print("Error getting contacts on MEGA: ", error)
                self.state = .error
            }
        }
        MEGASdkManager.sharedMEGASdk().getRegisteredContacts(deviceContacts, delegate: getRegisteredContactsDelegate)
    }
}
