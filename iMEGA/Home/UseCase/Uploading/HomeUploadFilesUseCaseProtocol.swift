import Foundation

protocol HomeUploadFilesUseCaseProtocol {

    /// Will return uploading options for current user.
    func uploadOptions() -> [FileUploadOption]

    /// Upload from photo albums
    /// - Parameters:
    ///   - photoIdentifiers: The photo identifiers that when selecting from photo album.
    ///   - parentHandle: The uploading target node's handle.
    func upload(photoIdentifiers: [String], to parentHandle: MEGAHandle) throws

    /// Upload from imports URL
    /// - Parameters:
    ///   - url: The local file path url of the uploading file.
    ///   - parentHandle: The uploading target node's handle.
    func upload(from url: URL, to parentHandle: MEGAHandle) throws

    /// Upload from Camera
    /// - Parameters:
    ///   - filePath: The file from where the file to be uploaded.
    ///   - parentHandle: The uploading target node's handle.
    func uploadFile(fromFilePath filePath: String, to node: MEGAHandle) throws

    /// Upload from scanned images
    /// - Parameters:
    ///   - images: The images to be uploaded.
    ///   - parentHandle: The uploading target node's handle.
    func uploadFile(fromSelectedImages images: [UIImage], to node: MEGAHandle) throws

}

final class HomeUploadFileUseCase: HomeUploadFilesUseCaseProtocol {

    func uploadOptions() -> [FileUploadOption] {
        if #available(iOS 13, *) {
            return [.photos, .textFile, .documentScan, .camera, .imports]
        } else {
            return [.photos, .textFile, .camera, .imports]
        }
    }

    func upload(photoIdentifiers: [String], to parentHandle: MEGAHandle) throws {
        uploadFromAlbum.upload(photoIdentifiers, parentHandle)
    }

    func upload(from url: URL, to parentHandle: MEGAHandle) throws {
        try uploadFromURL.upload(url, parentHandle)
    }

    func uploadFile(fromFilePath filePath: String, to parentNode: MEGAHandle) throws {
        try uploadFromLocalPath.upload(filePath, parentNode)
    }

    // Upload from scanned images
    func uploadFile(fromSelectedImages images: [UIImage], to parentNode: MEGAHandle) throws {
        let docuQuality = UserDefaults.standard.float(forKey: "DocScanQualityKey")
        let imageData = images.compactMap { image -> Data? in
            let scanQuality = DocScanQuality(rawValue: docuQuality) ?? .best
            return image.shrinkedImageData(docScanQuality: scanQuality)
        }

        let dataWithFilePaths = imageData.enumerated().map { data -> (String, Data) in
            let fileName = "Scan \(NSDate().mnz_formattedDefaultNameForMedia()) \(data.offset).jpg"
            let localFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
            return (localFilePath, data.element)
        }

        try dataWithFilePaths.forEach { (filePath, data) in
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            try uploadFromLocalPath.upload(filePath, parentNode)
        }
    }

    // MARK: - Properties

    private var uploadFromAlbum: UploadFromAlbum

    private var uploadFromURL: UploadFromURL

    private var uploadFromLocalPath: UploadFromLocalFilePath

    init(uploadFromAlbum: UploadFromAlbum, uploadFromURL: UploadFromURL, uploadFromLocalPath: UploadFromLocalFilePath) {
        self.uploadFromAlbum = uploadFromAlbum
        self.uploadFromURL = uploadFromURL
        self.uploadFromLocalPath = uploadFromLocalPath
    }
}

enum FileUploadOption {
    case photos
    case textFile
    case camera
    case imports
    case documentScan
}
