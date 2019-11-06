
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
    var deviceContactsChunked = [[[String:String]]]()

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
            let userContacts = MEGASdkManager.sharedMEGASdk().contacts()
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
            contacts.forEach { (contact) in
                for label in contact.phoneNumbers {
                    do {
                        let phoneNumber = try phoneNumberKit.parse(label.value.stringValue)
                        let formatedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
                        let name = contact.givenName + " " + contact.familyName

                        deviceContacts.append([formatedNumber:name])
                    }
                    catch {
                        print("Device contact number parser error " + label.value.stringValue)
                    }
                }
            }
            
            deviceContactsChunked = Array(deviceContacts.prefix(500)).mnz_chunked(into: 100)
            
            getContactsOnMega()
        } catch {
            state = .error
            print("Error fetching user contacts: ", error)
        }
    }
    
    private func getContactsOnMega() {
        var contactsOnMegaDictionary = [UInt64:String]()

        let getRegisteredContactsDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk {
                request.stringTableArray.forEach({ (contactOnMega) in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: contactOnMega[1])
                    if self.contacts.filter({$0.handle == userHandle}).count == 0 { //contactOnMega is not contact yet
                        guard let deviceContacts = self.deviceContactsChunked.first else { return }
                        for deviceContact in deviceContacts {
                            if let contactName = deviceContact[contactOnMega[0]] { //Get contactOnMega device name and save it to fetch email later
                                contactsOnMegaDictionary[userHandle] = contactName
                                break
                            }
                        }
                    }
                })
            } else {
                print("Error getting contacts on MEGA: ", error)
                self.state = .error
            }

            self.deviceContactsChunked.removeFirst()

            if self.deviceContactsChunked.count == 0 {
                self.fetchContactsOnMegaEmails(contactsOnMegaDictionary)
            } else {
                self.getContactsOnMega()
            }
        }
        
        MEGASdkManager.sharedMEGASdk().getRegisteredContacts(deviceContactsChunked.first!, delegate: getRegisteredContactsDelegate)
    }
    
    private func fetchContactsOnMegaEmails(_ contactsOnMegaDictionary: [UInt64:String]) {
        var contactsCount = contactsOnMegaDictionary.count
        contactsOnMegaDictionary.forEach { (contactOnMega) in
            let emailRequestDelegate = MEGAChatGenericRequestDelegate.init(completion: { (request, error) in
                self.contactsOnMega.append(ContactOnMega(handle: contactOnMega.key, email: request.text, name: contactOnMega.value))
                contactsCount -= 1
                if contactsCount == 0 {
                    self.state = .ready
                    if (self.completionWhenReady != nil) {
                        self.completionWhenReady!()
                    }
                }
            })
            MEGASdkManager.sharedMEGAChatSdk().userEmail(byUserHandle: contactOnMega.key, delegate: emailRequestDelegate)        }
    }
}
