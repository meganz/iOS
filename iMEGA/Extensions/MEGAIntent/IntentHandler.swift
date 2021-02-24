import Intents
import Firebase

class IntentHandler: INExtension {
    
    override init() {
        super.init()
        FirebaseApp.configure()
    }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}

extension IntentHandler: SelectShortcutIntentHandling {
    func provideShortcutOptionsCollection(for intent: SelectShortcutIntent, with completion: @escaping (INObjectCollection<IntentShortcut>?, Error?) -> Void) {
        let intentShortcuts = ShortcutDetail.availableShortcuts.map {
            IntentShortcut(identifier: $0.link, display: $0.title)
        }
        completion(INObjectCollection(items: intentShortcuts), nil)
    }
    
    func defaultShortcut(for intent: SelectShortcutIntent) -> [IntentShortcut]? {
        return ShortcutDetail.availableShortcuts.map {
            IntentShortcut(identifier: $0.link, display: $0.title)
        }
    }
}

extension IntentHandler: SelectSectionIntentHandling {
    func provideSectionOptionsCollection(for intent: SelectSectionIntent, with completion: @escaping (INObjectCollection<IntentSection>?, Error?) -> Void) {
        let intentSections = SectionDetail.availableSections.map {
            IntentSection(identifier: $0.link, display: $0.title)
        }
        completion(INObjectCollection(items: intentSections), nil)
    }
    
    func defaultSection(for intent: SelectSectionIntent) -> IntentSection?    {
        IntentSection(identifier: SectionDetail.defaultSection.link, display: SectionDetail.defaultSection.title )
    }
}
