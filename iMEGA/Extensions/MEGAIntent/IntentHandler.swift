import Intents
import Firebase

final class IntentHandler: INExtension {
    lazy var personProvider = IntentPersonProvider()
    
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
