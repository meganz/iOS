import Foundation
import FileProvider
import MobileCoreServices

@objc final class FileProviderItem: NSObject, NSFileProviderItem {
    var itemIdentifier: NSFileProviderItemIdentifier
    
    var parentItemIdentifier: NSFileProviderItemIdentifier
    
    var filename: String
    
    lazy var documentSize: NSNumber? = {
        try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? NSNumber
    }()
    
    lazy var typeIdentifier: String = {
        if url.hasDirectoryPath {
            return kUTTypeFolder as String
        } else {
            let pathExtension = url.pathExtension
            let unmanaged = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                pathExtension as CFString,
                nil
            )
            let retained = unmanaged?.takeRetainedValue()
            
            return (retained as String?) ?? ""
        }
    }()
    
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
        
        super.init()
    }
}
