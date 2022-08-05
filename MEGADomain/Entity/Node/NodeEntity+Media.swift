import Foundation
import MEGADomain

extension NodeEntity {
    var isVideo: Bool {
        (name as NSString).mnz_isVideoPathExtension
    }
    
    var isImage: Bool {
        (name as NSString).mnz_isImagePathExtension
    }
}
