import Foundation

struct Manager {
    enum Language {
        case english
        case other

        var url: URL {
            switch self {
            case .english: URL(string: "https://rest.api.transifex.com/resource_strings_async_downloads")!
            case .other: URL(string: "https://rest.api.transifex.com/resource_translations_async_downloads")!
            }
        }

        var httpBody: HttpBody {
            get throws {
                switch self {
                case .english: try HttpBody.loadEnglish()
                case .other: try HttpBody.loadOthers()
                }
            }
        }

        var transifexCode: String? {
            switch self {
            case .english: return "l:en"
            case .other: return nil
            }
        }
    }

    let languageInfo: LanguageInfo

    private var language: Language {
        languageInfo.transifexCode == Language.english.transifexCode ? .english : .other
    }

    private var httpBody: HttpBody {
        get throws {
            var httpBody = try language.httpBody
            if language == .other {
                httpBody.data.relationships.language?.data.id = languageInfo.transifexCode
            }

            return httpBody
        }
    }

    private var fetcher: Fetcher {
        get throws {
            Fetcher(
                url: language.url,
                httpBody: try httpBody,
                languageInfo: languageInfo
            )
        }
    }

    private var writer: Writer {
        Writer(
            folders: languageInfo.fastlaneMetadataFolders,
            languageName: languageInfo.name
        )
    }

    func fetch(with authorization: String) async throws -> String {
        try await fetcher.fetch(with: authorization)
    }

    func save(latestDescription: String) throws {
        try writer.write(latestDescription)
    }
}
