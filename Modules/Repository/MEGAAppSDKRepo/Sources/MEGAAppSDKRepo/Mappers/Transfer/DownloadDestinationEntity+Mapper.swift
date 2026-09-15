import MEGADomain

/// SDK documented contract mentioned at `MegaApi::startDownload`:
/// - If this path is a local folder, it must end with a '\' or '/' character and the file name in MEGA will be used to store a file inside that folder.
/// - If the path doesn't finish with one of these characters, the file will be downloaded to a file in that path.
public extension DownloadDestinationEntity {
    var toSDKLocalPath: String {
        let path = folder.path(percentEncoded: false)
        return path.hasSuffix("/") ? path : path + "/"
    }

    var toSDKCustomName: String? {
        name
    }
}
