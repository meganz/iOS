import Foundation
import FileProvider

@objc final class FileProviderItem: NSObject, NSFileProviderItem {
    var itemIdentifier: NSFileProviderItemIdentifier
    
    var parentItemIdentifier: NSFileProviderItemIdentifier
    
    var filename: String
    
    var documentSize: NSNumber?
    
    private let url: URL
    
    @objc init(url: URL) {
        self.url = url
        filename = url.lastPathComponent
        if url.path == "/" {
            itemIdentifier = .rootContainer
            parentItemIdentifier = itemIdentifier
        } else {
            itemIdentifier = NSFileProviderItemIdentifier(
                rawValue: url.dataRepresentation.base64EncodedString()
            )
            parentItemIdentifier = NSFileProviderItemIdentifier(
                rawValue: url.deletingLastPathComponent().dataRepresentation.base64EncodedString()
            )
        }
        
        documentSize = try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? NSNumber
    }
}
