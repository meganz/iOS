import Foundation

struct LanguageInfo: Decodable {
    let name: String
    let code: String
    let fastlaneMetadataFolders: [String]

    static var all: [LanguageInfo] {
        guard let url = Bundle.module.url(forResource: "languages", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let languages = try? JSONDecoder().decode([LanguageInfo].self, from: data) else {
            return []
        }
        return languages
    }
}
