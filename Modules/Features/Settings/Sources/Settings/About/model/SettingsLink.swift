import Foundation

public struct SettingsLink: Hashable {
    public var title: String
    public var url: URL
    
    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}
