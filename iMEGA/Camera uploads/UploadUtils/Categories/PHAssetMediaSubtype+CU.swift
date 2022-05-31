import Foundation
import Photos

extension PHAssetMediaSubtype {
    
    /// Raw image is not officialy documented by Apple. But upon checking the pro-raw images taken on iOS devices, the `PHAssetMediaSubtype` is 1UL << 9.
    /// So, here we create a convenient media subtype to check if the current asset is a raw image.
    static var mnz_rawImage: PHAssetMediaSubtype {
        PHAssetMediaSubtype(rawValue: UInt(1) << 9)
    }
}
