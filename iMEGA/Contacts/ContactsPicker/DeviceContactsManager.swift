
import UIKit

class DeviceContact: NSObject {
    
    var name: String
    var avatarData: Data?
    var value: String
    var valueLabel: String?
    var isSelected: Bool = false
    
    init(name: String, avatarData: Data?, value: String, valueLabel: String?) {
        self.name = name
        self.value = value
        self.valueLabel = valueLabel
        self.avatarData = avatarData
        super.init()
    }
}

class DeviceContactsManager: NSObject {
        
    func getDeviceContacts(for requestedKeys: [String]) -> [DeviceContact] {
        
        var fetchedContacts = [DeviceContact]()
        let contactStore = CNContactStore()
        
        var keys = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
        
        requestedKeys.forEach { (key) in
            keys.append(key as CNKeyDescriptor)
        }

        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
        do {
            let phoneNumberKit = PhoneNumberKit()

            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
            contacts.forEach { (contact) in
                let name = (contact.givenName + " " + contact.familyName)
                
                if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
                    for phone in contact.phoneNumbers {
                        do {
                            let phoneNumber = try phoneNumberKit.parse(phone.value.stringValue)
                            let formatedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
                            
                            fetchedContacts.append(DeviceContact(name: name, avatarData: contact.thumbnailImageData, value: formatedNumber, valueLabel: phone.label))
                        }
                        catch {
                            MEGALogError("Device contact number parser error " + phone.value.stringValue)
                        }
                    }
                }

                if contact.isKeyAvailable(CNContactEmailAddressesKey) {
                    contact.emailAddresses.forEach { (email) in
                        if email.value.mnz_isValidEmail() {
                            fetchedContacts.append(DeviceContact(name: name, avatarData: contact.thumbnailImageData, value: String(email.value), valueLabel: email.label))
                        } else {
                            MEGALogError("Device contact email not valid: " + String(email.value))
                        }
                    }
                }
            }
            return fetchedContacts
        } catch {
            MEGALogError("Error fetching user contacts: " + error.localizedDescription)
            return []
        }
    }
}
