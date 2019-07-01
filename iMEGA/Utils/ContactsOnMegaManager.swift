
import Contacts

@objc class ContactsOnMegaManager: NSObject {
    
    enum ContactsOnMegaState {
        case unknown
        case fetching
        case ready
        case error
    }
    
    var state = ContactsOnMegaState.unknown
    var countryCallingCodes = [String : MEGAStringList]()
    var contactsOnMega = [MEGAStringList]()
    
    var completionWhenReady : (() -> Void)?

    @objc static let shared: ContactsOnMegaManager = {
        return ContactsOnMegaManager()
    }()
    
    private override init() {}
    
    @objc func fetchContactsOnMega() -> [Any]? {
        if state == .ready {
            #warning ("this is a mock meanwhile the api returns 0 contacts on mega")
            return [0, 1, 3]
//            return contactsOnMega
        } else {
            return nil
        }
    }

    @objc func configureContactsOnMega(completion: (() -> Void)?) {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            completionWhenReady = completion
            state = .fetching
            getCountryCallingCodes()
        }
    }
    
    private func getCountryCallingCodes() {
        let getCountryCallingCodesDelegate = MEGAGetCountryCallingCodesRequestDelegate.init { (request, error) in
            self.countryCallingCodes = request.megaStringListDictionary as [String : MEGAStringList]
            self.getDeviceContacts()
        }
        MEGASdkManager.sharedMEGASdk()?.getCountryCallingCodes(with: getCountryCallingCodesDelegate)
    }
    
    private func getDeviceContacts() {
        var deviceContacts = [[String:String]]()
        let contactsStore = CNContactStore()

        let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]

        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore.defaultContainerIdentifier())
        do {
            let contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            for contact in contacts {
                for label in contact.phoneNumbers {
                    let countryLocale = label.value.value(forKey: "countryCode") as? String
                    var phoneNumber = label.value.stringValue.replacingOccurrences(of: " ", with: "")
                    let name = contact.givenName + " " + contact.familyName
                    
                    if !phoneNumber.contains("+") {
                        guard let countrYCodes = countryCallingCodes[countryLocale!.uppercased()] else {return}
                        phoneNumber = "+" + countrYCodes.string(at: 0) + phoneNumber
                    }
                    
                    deviceContacts.append([phoneNumber:name])
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
                self.contactsOnMega = request.megaStringTableArray
                self.state = .ready
                if (self.completionWhenReady != nil) {
                    self.completionWhenReady!()
                }
            } else {
                print("Error getting contacts on MEGA: ", error)
                self.state = .error
            }
        }
        MEGASdkManager.sharedMEGASdk()?.getRegisteredContacts(deviceContacts, delegate: getRegisteredContactsDelegate)
    }
}
