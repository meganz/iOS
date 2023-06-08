
struct EmojiListReader {
    static func readFromFile() -> [Emoji]? {
        guard let path = Bundle.main.path(forResource: "emojis_v3", ofType: "json") else {
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode([Emoji].self, from: jsonData)
        } catch {
            MEGALogDebug("Could not read emojis_v3 json file \(error.localizedDescription)")
        }
        
        return nil
    }
}

struct Emoji: Codable {
    let category: Int
    let representation: String
    let name: String
    
    private enum CodingKeys: String, CodingKey {
        case category = "c"
        case representation = "u"
        case name = "n"
    }
}
