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
    var deviceContactsChunked = [[[String: String]]]()
    var contactsOnMegaDictionary = [UInt64: String]()

    var completionWhenReady : (() -> Void)?

    @objc static let shared = ContactsOnMegaManager()

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
        let outgoingContactRequestList = MEGASdkManager.sharedMEGASdk().outgoingContactRequests()
        for i in 0 ..< outgoingContactRequestList.size.intValue {
            contactEmailsToFilter.append(outgoingContactRequestList.contactRequest(at: i)?.targetEmail.lowercased() ?? "")
        }

        //Get all visible contacts emails
        let userContacts = MEGASdkManager.sharedMEGASdk().contacts()
        for j in 0 ..< userContacts.size.intValue {
            if let user = userContacts.user(at: j) {
                if user.visibility == .visible {
                    contactEmailsToFilter.append(user.email.lowercased())
                }
            }
        }

        //Filter ContactsOnMEGA from API with outgoing contact request and visible contacts
        if contactEmailsToFilter.count > 0 {
            for contact in contactsOnMega {
                if contactEmailsToFilter.filter({$0 == contact.email.lowercased()}).count == 0 {
                    contactsOnMegaFiltered.append(contact)
                }
            }
            return contactsOnMegaFiltered
        } else {
            return contactsOnMega
        }
    }

    @objc func areContactsOnMegaRequestedWithin(days: Int) -> Bool {
        guard let lastDateContactsOnMegaRequested = UserDefaults.standard.value(forKey: "lastDateContactsOnMegaRequested"), let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastDateContactsOnMegaRequested as! Date, to: Date()).day else {
            return false
        }

        return daysSinceLastRequest < days
    }

    @objc func loadContactsOnMegaFromLocal() {
        contactsOnMega = UserDefaults.standard.structArrayData(ContactOnMega.self, forKey: "ContactsOnMega")
        contactsFetched()
    }

    @objc func configureContactsOnMega(completion: (() -> Void)?) {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            completionWhenReady = completion

            if state == .fetching { return }
            state = .fetching

            contactsOnMega.removeAll()
            UserDefaults.standard.removeObject(forKey: "ContactsOnMega")

            DispatchQueue.global(qos: .background).async {
                self.getDeviceContacts()
            }
        } else {
            MEGALogDebug("Device Contact Permission not granted")
        }
    }

    private func getDeviceContacts() {
        var deviceContacts = [[String: String]]()
        let contactsStore = CNContactStore()

        let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]

        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore.defaultContainerIdentifier())
        do {
            let phoneNumberKit = PhoneNumberKit()

            let contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            contacts.forEach { (contact) in
                let name = (contact.givenName + " " + contact.familyName)

                for label in contact.phoneNumbers {
                    do {
                        let phoneNumber = try phoneNumberKit.parse(label.value.stringValue)
                        let formatedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)

                        deviceContacts.append([formatedNumber:name])
                    }
                    catch {
                        MEGALogError("Device contact number parser error " + label.value.stringValue)
                    }
                }

                contact.emailAddresses.forEach { (email) in
                    if email.value.mnz_isValidEmail() {
                        deviceContacts.append([String(email.value):name])
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
        let getRegisteredContactsDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk {
                request.stringTableArray.forEach({ (contactOnMega) in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: contactOnMega[1])
                    guard let deviceContacts = self.deviceContactsChunked.first else { return }
                    for deviceContact in deviceContacts {
                        if let contactName = deviceContact[contactOnMega[0]] { //Get contactOnMega device name and save it to fetch email later
                            self.contactsOnMegaDictionary[userHandle] = contactName
                            break
                        }
                    }
                })
            } else {
                MEGALogError("Error getting contacts on MEGA: " + error.name)
                self.state = .error
            }

            if self.deviceContactsChunked.count > 0 {
                self.deviceContactsChunked.removeFirst()
            }

            if self.deviceContactsChunked.count == 0 {
                self.fetchContactsOnMegaEmails(self.contactsOnMegaDictionary)
            } else {
                self.getContactsOnMega()
            }
        }

        guard let firstChunkOfContacts = deviceContactsChunked.first else { return }
        MEGASdkManager.sharedMEGASdk().getRegisteredContacts(firstChunkOfContacts, delegate: getRegisteredContactsDelegate)
    }

    private func fetchContactsOnMegaEmails(_ contactsOnMegaDictionary: [UInt64: String]) {
        var contactsCount = contactsOnMegaDictionary.count
        if contactsCount == 0 {
            contactsFetched()
        }
        contactsOnMegaDictionary.forEach { (contactOnMega) in
            let emailRequestDelegate = MEGAChatGenericRequestDelegate.init(completion: { (request, _) in
                if request.text != MEGASdkManager.sharedMEGASdk()?.myEmail {
                    self.contactsOnMega.append(ContactOnMega(handle: contactOnMega.key, email: request.text, name: contactOnMega.value))
                }
                contactsCount -= 1
                if contactsCount == 0 {
                    self.persistContactsOnMega()
                }
            })
            MEGASdkManager.sharedMEGAChatSdk()?.userEmail(byUserHandle: contactOnMega.key, delegate: emailRequestDelegate)
        }
    }

    private func contactsFetched() {
        UserDefaults.standard.set(Date(), forKey: "lastDateContactsOnMegaRequested")
        self.state = .ready
        guard let completion = completionWhenReady else { return }
        DispatchQueue.main.async {
            completion()
        }
        completionWhenReady = nil
    }

    private func persistContactsOnMega() {
        UserDefaults.standard.setStructArray(contactsOnMega, forKey: "ContactsOnMega")
        contactsFetched()
    }
}
