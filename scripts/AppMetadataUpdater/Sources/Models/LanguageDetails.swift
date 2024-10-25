import Foundation

enum LanguageDetails {
    case english
    case other

    var url: URL {
        switch self {
        case .english: URL(string: "https://rest.api.transifex.com/resource_strings_async_downloads")!
        case .other: URL(string: "https://rest.api.transifex.com/resource_translations_async_downloads")!
        }
    }

    var transifexCode: String? {
        switch self {
        case .english: return "l:en"
        case .other: return nil
        }
    }

    func httpBody() throws -> HttpBody {
        switch self {
        case .english:
            try HttpBody.loadEnglish()
        case .other:
            try HttpBody.loadOthers()
        }
    }

    init(languageInfo: LanguageInfo) {
        self = languageInfo.transifexCode == LanguageDetails.english.transifexCode ? .english : .other
    }
}
