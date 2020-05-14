
struct AddToChatMenu: Codable {
    let nameKey: String
    let imageKey: String
    let dynamicKey: Bool
    
    static func menus() -> [AddToChatMenu]? {
        if let fileURL = Bundle.main.url(forResource: "AddToChatMenus",   withExtension: "plist")  {
            do {
                let propertyListDecoder = PropertyListDecoder()
                let data = try Data(contentsOf: fileURL)
                return try propertyListDecoder.decode([AddToChatMenu].self, from: data)
            } catch {
                print(error)
            }
        }
        
        return nil
    }
}
