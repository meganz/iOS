struct AddToChatMenu: Codable {
    enum MenuNameKey: String {
        case photos = "photo.navigation.title"
        case file = "cloudDrive"
        case filesApp = "chat.addToChatMenu.filesApp"
        case contact = "Contact"
        case scanDoc = "chat.addToChatMenu.scan"
        case location = "chat.map.location"
        case voiceClip = "Voice Clip"
        case giphy = "GIF"
    }
    
    let nameKey: String
    let imageKey: String
    
    static func menus() -> [AddToChatMenu]? {
        if let fileURL = Bundle.main.url(forResource: "AddToChatMenus", withExtension: "plist") {
            do {
                let propertyListDecoder = PropertyListDecoder()
                let data = try Data(contentsOf: fileURL)
                return try propertyListDecoder.decode([AddToChatMenu].self, from: data)
            } catch {
                MEGALogDebug(error.localizedDescription)
            }
        }
        
        return nil
    }
    
    var menuNameKey: MenuNameKey? {
        switch nameKey {
        case MenuNameKey.photos.rawValue:
            return .photos
        case MenuNameKey.file.rawValue:
            return .file
        case MenuNameKey.filesApp.rawValue:
            return .filesApp
        case MenuNameKey.contact.rawValue:
            return .contact
        case MenuNameKey.scanDoc.rawValue:
            return .scanDoc
        case MenuNameKey.location.rawValue:
            return .location
        case MenuNameKey.voiceClip.rawValue:
            return .voiceClip
        case MenuNameKey.giphy.rawValue:
            return .giphy
        default:
            return nil
        }
    }
}
