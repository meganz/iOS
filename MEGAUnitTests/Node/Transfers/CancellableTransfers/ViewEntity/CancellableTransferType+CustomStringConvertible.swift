@testable import MEGA

extension CancellableTransferType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .download:
            return "Download"
        case .upload:
            return "Upload"
        case .downloadChat:
            return "DownloadChat"
        case .downloadFileLink:
            return "DownloadFileLink"
        }
    }
}
