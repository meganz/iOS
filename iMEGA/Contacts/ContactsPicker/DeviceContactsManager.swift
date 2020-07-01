
import UIKit

protocol DeviceContactProtocol {
    var name: String { get }
    var avatarData: Data? { get }
    var contactDetail: String { get } //Could be a phone number or a email address
    var contactDetailDescription: String?  { get } //Label to specify the contact detail (Home, Work, iPhone...)
}

struct DeviceContact: DeviceContactProtocol, Hashable {
    let name: String
    let avatarData: Data?
    let contactDetail: String
    let contactDetailDescription: String?
}

class DeviceContactsManager: NSObject {
    
    func getDeviceContacts(forRequestedKeys keys: [String], completion: @escaping (_ contacts: [DeviceContact]) -> ()) {
        DispatchQueue.global(qos: .background).async {
            
            var fetchedContacts = [DeviceContact]()
            let contactStore = CNContactStore()
            
            var fetchKeys = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
            
            keys.forEach { (key) in
                fetchKeys.append(key as CNKeyDescriptor)
            }
            
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
            do {
                let phoneNumberKit = PhoneNumberKit()
                
                let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: fetchKeys)
                contacts.forEach { (contact) in
                    let name = (contact.givenName + " " + contact.familyName)
                    
                    if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
                        for phone in contact.phoneNumbers {
                            do {
                                let phoneNumber = try phoneNumberKit.parse(phone.value.stringValue)
                                let formatedNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
                                
                                fetchedContacts.append(DeviceContact(name: name, avatarData: contact.thumbnailImageData, contactDetail: formatedNumber, contactDetailDescription: phone.label))
                            }
                            catch {
                                MEGALogError("Device contact number parser error " + phone.value.stringValue)
                            }
                        }
                    }
                    
                    if contact.isKeyAvailable(CNContactEmailAddressesKey) {
                        contact.emailAddresses.forEach { (email) in
                            if email.value.mnz_isValidEmail() {
                                fetchedContacts.append(DeviceContact(name: name, avatarData: contact.thumbnailImageData, contactDetail: String(email.value), contactDetailDescription: email.label))
                            } else {
                                MEGALogError("Device contact email not valid: " + String(email.value))
                            }
                        }
                    }
                }
                DispatchQueue.global(qos: .background).async {
                }
                
                completion(fetchedContacts)
            } catch {
                MEGALogError("Error fetching user contacts: " + error.localizedDescription)
                completion([])
            }
        }
    }
}
