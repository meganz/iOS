
import Contacts

struct ContactOnMega: Codable {
    let handle: UInt64
    let email: String
    let name: String
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
    var deviceContactsChunked = [[[String:String]]]()

    var completionWhenReady : (() -> Void)?

    @objc static let shared: ContactsOnMegaManager = {
        return ContactsOnMegaManager()
    }()
    
    private override init() {}
    
    @objc func contactsOnMegaCount() -> NSInteger {
        if state == .ready {
            return contactsOnMegaFiltered().count
        } else {
            return 0
        }
    }
    
    func fetchContactsOnMega() -> [ContactOnMega]? {
        if state == .ready {
            return contactsOnMegaFiltered()
        } else {
            return nil
        }
    }

    private func contactsOnMegaFiltered() -> [ContactOnMega] {
        var contactsOnMegaFiltered = [ContactOnMega]()
        var contactEmailsToFilter = [String]()

        //Get all outgoing contact request emails
        let outgoingContactRequestList = MEGASdkManager.sharedMEGASdk()?.outgoingContactRequests()
        guard let outgoingContactRequestSize = outgoingContactRequestList?.size.intValue else {
            return contactsOnMega
        }
        for i in 0 ..< outgoingContactRequestSize {
            contactEmailsToFilter.append(outgoingContactRequestList?.contactRequest(at: i)?.targetEmail ?? "")
        }
        
        //Get all visible contacts emails
        let userContacts = MEGASdkManager.sharedMEGASdk()?.contacts()
        guard let userContactsSize = userContacts?.size.intValue else {
            return contactsOnMega
        }
        for j in 0 ..< userContactsSize {
            guard let user = userContacts?.user(at: j) else {
                return contactsOnMega
            }
            if user.visibility == .visible {
                contactEmailsToFilter.append(user.email)
            }
        }
        
        //Filter ContactsOnMEGA from API with outgoing contact request and visible contacts
        for contact in contactsOnMega {
            if contactEmailsToFilter.filter({$0 == contact.email}).count == 0 {
                contactsOnMegaFiltered.append(contact)
            }
        }
        
        return contactsOnMegaFiltered
    }
    
    @objc func areContactsOnMegaRequestedWithin(days: Int) -> Bool {
        let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier)
        guard let lastDateContactsOnMegaRequested = sharedUserDefaults?.value(forKey: "lastDateContactsOnMegaRequested") else {
            return false
        }
        guard let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastDateContactsOnMegaRequested as! Date, to: Date()).day else {
            return false
        }
        if daysSinceLastRequest >= days {
            return false
        } else {
            return true
        }
    }
    
    @objc func loadContactsOnMegaFromLocal() {
        guard let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) else { return }
        contactsOnMega = sharedUserDefaults.structArrayData(ContactOnMega.self, forKey: "ContactsOnMega")
        contactsFetched()
        print(contactsOnMega)
    }
    
    @objc func configureContactsOnMega(completion: (() -> Void)?) {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            contactsOnMega.removeAll()
            guard let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) else { return }
            sharedUserDefaults.removeObject(forKey: "ContactsOnMega")
            
            completionWhenReady = completion
            state = .fetching
            getDeviceContacts()
        } else {
            MEGALogDebug("Device Contact Permission not granted")
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
                        MEGALogError("Device contact number parser error " + label.value.stringValue)
                    }
                }
            }
            
            if deviceContacts.count == 0 {
                contactsFetched()
            } else {
                deviceContactsChunked = Array(deviceContacts.prefix(500)).mnz_chunked(into: 100)
                getContactsOnMega()
            }
        } catch {
            state = .error
            MEGALogError("Error fetching user contacts: " + error.localizedDescription)
        }
    }
    
    private func getContactsOnMega() {
        var contactsOnMegaDictionary = [UInt64:String]()

        let getRegisteredContactsDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk {
                request.stringTableArray.forEach({ (contactOnMega) in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: contactOnMega[1])
                    guard let deviceContacts = self.deviceContactsChunked.first else { return }
                    for deviceContact in deviceContacts {
                        if let contactName = deviceContact[contactOnMega[0]] { //Get contactOnMega device name and save it to fetch email later
                            contactsOnMegaDictionary[userHandle] = contactName
                            break
                        }
                    }
                })
            } else {
                MEGALogError("Error getting contacts on MEGA: " + error.name)
                self.state = .error
            }

            self.deviceContactsChunked.removeFirst()

            if self.deviceContactsChunked.count == 0 {
                self.fetchContactsOnMegaEmails(contactsOnMegaDictionary)
            } else {
                self.getContactsOnMega()
            }
        }
        
        guard let firstChunkOfContacts = deviceContactsChunked.first else { return }
        MEGASdkManager.sharedMEGASdk().getRegisteredContacts(firstChunkOfContacts, delegate: getRegisteredContactsDelegate)
    }
    
    private func fetchContactsOnMegaEmails(_ contactsOnMegaDictionary: [UInt64:String]) {
        var contactsCount = contactsOnMegaDictionary.count
        if contactsCount == 0 {
            contactsFetched()
        }
        contactsOnMegaDictionary.forEach { (contactOnMega) in
            let emailRequestDelegate = MEGAChatGenericRequestDelegate.init(completion: { (request, error) in
                if request.text != MEGASdkManager.sharedMEGASdk()?.myEmail {
                    self.contactsOnMega.append(ContactOnMega(handle: contactOnMega.key, email: request.text, name: contactOnMega.value))
                }
                contactsCount -= 1
                if contactsCount == 0 {
                    self.persistContactsOnMega()
                }
            })
            MEGASdkManager.sharedMEGAChatSdk().userEmail(byUserHandle: contactOnMega.key, delegate: emailRequestDelegate)
        }
    }
    
    private func contactsFetched() {
        self.state = .ready
        if (self.completionWhenReady != nil) {
            self.completionWhenReady!()
        }
    }
    
    private func persistContactsOnMega() {
        guard let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) else { return }
        sharedUserDefaults.setStructArray(contactsOnMega, forKey: "ContactsOnMega")
        sharedUserDefaults.set(Date(), forKey: "lastDateContactsOnMegaRequested")

        contactsFetched()
    }
}
