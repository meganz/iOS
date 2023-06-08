import Foundation

final class MEGAURLAsset: AVURLAsset {
    var name: String
    var author: String?
    var album: String?
    var artwork: Data?
    var node: MEGAHandle?
    
    init(name: String, url: URL, options: [String: Any]? = nil) {
        self.name = name
        super.init(url: url, options: options)
    }
}
