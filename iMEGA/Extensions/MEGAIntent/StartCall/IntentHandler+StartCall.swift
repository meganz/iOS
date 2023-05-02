import Intents
import Contacts
import MEGADomain
import MEGASdk
import MEGAData

extension IntentHandler: INStartCallIntentHandling {
    
    func handle(intent: INStartCallIntent) async -> INStartCallIntentResponse {
        let userActivity = NSUserActivity(activityType: String(describing: INStartCallIntent.self))
        
        guard intent.contacts?.first?.personHandle?.value != nil else {
            return INStartCallIntentResponse(code: .failureContactNotSupportedByApp, userActivity: userActivity)
        }
        
        let response = INStartCallIntentResponse(code: .continueInApp, userActivity: userActivity)
        return response
    }
    
    func resolveContacts(for intent: INStartCallIntent) async -> [INStartCallContactResolutionResult] {
        let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)
        
        guard credentialUseCase.hasSession() else {
            return [.unsupported(forReason: .invalidHandle)]
        }
        
        if credentialUseCase.isPasscodeEnabled() {
            return [.unsupported(forReason: .invalidHandle)]
        }
        
        guard let contacts = intent.contacts else {
            return [.unsupported(forReason: .invalidHandle)]
        }
        
        guard contacts.count == 1 else {
            return [.unsupported(forReason: .multipleContactsUnsupported)]
        }
        
        guard let person = contacts.first else {
            return [.unsupported(forReason: .invalidHandle)]
        }
        
        let personHasEmail = person.personHandle?.value != nil
        if personHasEmail {
            return [.success(with: person)]
        }
        
        let authorizedToUseContacts = CNContactStore.authorizationStatus(for: .contacts) == .authorized
        guard authorizedToUseContacts else {
            return [.unsupported(forReason: .noContactFound)]
        }
        
        let persons = personProvider.personsInContacts(person)
        
        guard persons.isNotEmpty else {
            return [.unsupported(forReason: .noContactFound)]
        }
        
        if persons.count == 1, let person = persons.first {
            return [.success(with: person)]
        }
        
        return [.disambiguation(with: persons)]
    }
}

