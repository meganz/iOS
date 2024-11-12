@preconcurrency import QuickLookThumbnailing

protocol FileAttributeGeneratorProtocol: Sendable {
    /// Create a square (200px x 200px) thumbnail from the original source (cropped in the center of the image)
    /// - Parameter destinationURL: url where the thumbnail will be saved
    /// - Returns: true if the thumbnail is created, otherwise false
    ///
    /// - Note: two steps involved when creating a thubmnail:
    ///     1. Get scaled thumbnail (min side 200px)
    ///     2. Crop it at the center of the image (200px x 200px)
    func createThumbnail(at destinationURL: URL) async -> Bool
    /// Create a scaled preview (max 1000px) from the original source
    /// - Parameter destinationURL: url where the preview will be saved
    /// - Returns: true if the preview is created, otherwise false
    func createPreview(at destinationURL: URL) async -> Bool
    
    /// Thumbnail representation for a file
    /// - Returns: return thumbnail image for a file
    func requestThumbnail() async -> UIImage?
}

final class FileAttributeGenerator: NSObject, FileAttributeGeneratorProtocol {

    private let sourceURL: URL
    private let pixelWidth: Int
    private let pixelHeight: Int
    private let qlThumbnailGenerator: QLThumbnailGenerator
    
    enum Constants {
        static let thumbnailSize = 200
        static let previewSize = 1000
        static let compressionQuality = 0.8
    }
    
    init(sourceURL: URL, pixelWidth: Int = 0, pixelHeight: Int = 0, qlThumbnailGenerator: QLThumbnailGenerator = QLThumbnailGenerator.shared) {
        self.sourceURL = sourceURL
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.qlThumbnailGenerator = qlThumbnailGenerator
    }
    
    func createThumbnail(at destinationURL: URL) async -> Bool {
        let size = sizeForThumbnail()
        do {
            let representation = try await generateThumbnail(size: size)
            guard let newImage = representation.cgImage.cropping(to: tileRect(width: representation.cgImage.width, height: representation.cgImage.height)) else { return false }
            let data = UIImage(cgImage: newImage).jpegData(compressionQuality: Constants.compressionQuality)
            try data?.write(to: destinationURL)
        } catch let error {
            MEGALogError("[Camera Uploads] create thumbnail fails for \(sourceURL.lastPathComponent) with error \(error)")
            return false
        }
        MEGALogDebug("[Camera Uploads] create thumbnail correctly at \(destinationURL)")
        return true
    }
    
    func createPreview(at destinationURL: URL) async -> Bool {
        let size = CGSize(width: Constants.previewSize, height: Constants.previewSize)
        let request = QLThumbnailGenerator.Request(fileAt: sourceURL,
                                                   size: size,
                                                   scale: 1.0,
                                                   representationTypes: .thumbnail)
        
        do {
            try await qlThumbnailGenerator.saveBestRepresentation(for: request, to: destinationURL, contentType: UTType.jpeg.identifier)
        } catch let error {
            MEGALogError("[Camera Uploads] create preview fails for \(sourceURL.lastPathComponent) with error \(error)")
            return false
        }
        MEGALogDebug("[Camera Uploads] create preview correctly at \(destinationURL)")
        return true
    }
    
    func requestThumbnail() async -> UIImage? {
        let size = CGSize(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
        
        do {
            let representation = try await generateThumbnail(size: size)
            return representation.uiImage
        } catch let error {
            let retryResult = try? await generateThumbnail(size: size, presentationType: .all).uiImage
            MEGALogDebug("Create thumbnail for local file \(sourceURL.lastPathComponent) fails with error \(error). Retried with result: \(retryResult != nil ? "Success" : "Failure")")
            return retryResult
        }
    }
    
    // MARK: - Private
    
    private func generateThumbnail(size: CGSize, presentationType: QLThumbnailGenerator.Request.RepresentationTypes = .thumbnail) async throws -> QLThumbnailRepresentation {
        let request = QLThumbnailGenerator.Request(fileAt: sourceURL,
                                                   size: size,
                                                   scale: 1.0,
                                                   representationTypes: presentationType)
        return try await qlThumbnailGenerator.generateBestRepresentation(for: request)
    }
    
    /// Size for scaled thumbnail
    /// - Returns: return size for the scaled thumbnail (min side is 200px)
    private func sizeForThumbnail() -> CGSize {
        var w: Int
        var h: Int
        if pixelWidth > pixelHeight && pixelHeight > 0 {
            h = Constants.thumbnailSize
            w = Constants.thumbnailSize * pixelWidth / pixelHeight
        } else if pixelHeight > pixelWidth && pixelWidth > 0 {
            h = Constants.thumbnailSize * pixelHeight / pixelWidth
            w = Constants.thumbnailSize
        } else {
            w = Constants.thumbnailSize
            h = Constants.thumbnailSize
        }
        return CGSize(width: w, height: h)
    }
    
    private func tileRect(width: Int, height: Int) -> CGRect {
        var rect: CGRect = CGRect()
        rect.size.width = CGFloat(min(width, height))
        rect.size.height = CGFloat(min(width, height))
        
        if width < height {
            rect.origin.x = 0
            rect.origin.y = CGFloat((height - width) / 2)
        } else {
            rect.origin.x = CGFloat((width - height) / 2)
            rect.origin.y = 0
        }
        return rect
    }
}

#if DEBUG
extension FileAttributeGenerator {
    func functionToTest_sizeForThumbnail() -> CGSize {
        sizeForThumbnail()
    }
    
    func functionToTest_tileRect(width: Int, height: Int) -> CGRect {
        tileRect(width: width, height: height)
    }
}
#endif
