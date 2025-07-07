import Contacts
import Intents
import SAMKeychain

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
        guard SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil else {
            return [.unsupported(forReason: .invalidHandle)]
        }
        
        if SAMKeychain.password(forService: "MEGA", account: "demoPasscode") != nil {
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

        let authorizationStatusForContacts = CNContactStore.authorizationStatus(for: .contacts)

        switch authorizationStatusForContacts {
        case .notDetermined:
            return await handleUndeterminedAuthorizationToContacts(for: person)
        case .restricted, .denied:
            return [.unsupported(forReason: .noContactFound)]
        case .authorized:
            return processResolutionInContacts(for: person)
        case .limited:
            return processResolutionInContacts(for: person)
        @unknown default:
            return [.unsupported(forReason: .noContactFound)]
        }
    }

    func handleUndeterminedAuthorizationToContacts(for person: INPerson) async -> [INStartCallContactResolutionResult] {
        let store = CNContactStore()

        do {
            let isAuthorized = try await store.requestAccess(for: .contacts)

            guard isAuthorized else {
                return [.unsupported(forReason: .noContactFound)]
            }

            return processResolutionInContacts(for: person)
        } catch {
            return [.unsupported(forReason: .noContactFound)]
        }
    }

    func processResolutionInContacts(for person: INPerson) -> [INStartCallContactResolutionResult] {
        let persons = intentPersonUseCase.personsInContacts(matching: person)

        guard persons.isNotEmpty else {
            return [.unsupported(forReason: .noContactFound)]
        }

        if persons.count == 1, let person = persons.first {
            return [.success(with: person)]
        }

        return [.disambiguation(with: persons)]
    }
}
