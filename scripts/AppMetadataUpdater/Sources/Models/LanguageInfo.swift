import Foundation

struct LanguageInfo {
    let name: String
    let transifexCode: String
    let fastlaneMetadataFolders: [String]

    static var all: [LanguageInfo] {
        [
            LanguageInfo(name: "English", transifexCode: "l:en", fastlaneMetadataFolders: ["en-US", "en-GB"]),
            LanguageInfo(name: "Spanish", transifexCode: "l:es", fastlaneMetadataFolders: ["es-ES", "es-MX"]),
            LanguageInfo(name: "Arabic", transifexCode: "l:ar", fastlaneMetadataFolders: ["ar-SA"]),
            LanguageInfo(name: "French", transifexCode: "l:fr", fastlaneMetadataFolders: ["fr-CA", "fr-FR"]),
            LanguageInfo(name: "Indonesian", transifexCode: "l:id", fastlaneMetadataFolders: ["id"]),
            LanguageInfo(name: "Italian", transifexCode: "l:it", fastlaneMetadataFolders: ["it"]),
            LanguageInfo(name: "Japanese", transifexCode: "l:ja", fastlaneMetadataFolders: ["ja"]),
            LanguageInfo(name: "Korean", transifexCode: "l:ko", fastlaneMetadataFolders: ["ko"]),
            LanguageInfo(name: "Dutch", transifexCode: "l:nl", fastlaneMetadataFolders: ["nl-NL"]),
            LanguageInfo(name: "Polish", transifexCode: "l:pl", fastlaneMetadataFolders: ["pl"]),
            LanguageInfo(name: "Portuguese", transifexCode: "l:pt", fastlaneMetadataFolders: ["pt-BR", "pt-PT"]),
            LanguageInfo(name: "Romanian", transifexCode: "l:ro", fastlaneMetadataFolders: ["ro"]),
            LanguageInfo(name: "Thai", transifexCode: "l:th", fastlaneMetadataFolders: ["th"]),
            LanguageInfo(name: "Vietnamese", transifexCode: "l:vi", fastlaneMetadataFolders: ["vi"]),
            LanguageInfo(name: "Chinese Simpified", transifexCode: "l:zh_CN", fastlaneMetadataFolders: ["zh-Hans"]),
            LanguageInfo(name: "Chinese Traditional", transifexCode: "l:zh_TW", fastlaneMetadataFolders: ["zh-Hant"]),
            LanguageInfo(name: "German", transifexCode: "l:de", fastlaneMetadataFolders: ["de-DE"]),
            LanguageInfo(name: "Turkish", transifexCode: "l:tr", fastlaneMetadataFolders: ["tr"])
        ]
    }
}
