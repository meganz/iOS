import Foundation

class ServiceConstant {
    
    // MARK: - Properties
    static let gifs: String = "v1/gifs"
    static let stickers: String = "v1/stickers"
    static let text: String = "v1/texts"
    static let emoji: String = "v1/emojis"
    
    static func path(_ category: GiphyCatogory) -> String {
        switch category {
        case .gifs:
            return gifs
        case .stickers:
            return stickers
        case .text:
            return text
        case .emoji:
            return emoji
        }
    }
}
