import Foundation
import MEGAPreference

public protocol CameraUploadFileDetailsUseCaseProtocol: Sendable {
    /// Retrieves detailed file information for the given local identifiers.
    ///
    /// This method is typically used to obtain metadata about specific files
    /// such as name, size, or creation details.
    ///
    /// - Parameter identifiers: A set of local identifiers representing the files to look up.
    ///
    /// - Returns: An array of `CameraUploadFileDetailsEntity` objects containing detailed file information.
    ///
    /// - Throws: An error if retrieving file details fails.
    func fileDetails(
        forLocalIdentifiers identifiers: Set<String>
    ) async throws -> Set<CameraUploadFileDetailsEntity>
    
    /// Generates the upload file name for a given camera asset.
    ///
    /// The resulting file name incorporates:
    /// - A standardised date-based prefix derived from the asset's creation date.
    /// - Media-specific file extensions, including rules for:
    ///   - HEIC conversion to JPG (if preference is enabled)
    ///   - Live photos
    ///   - Burst photos
    ///
    /// - Parameter assetUploadEntity: The camera asset entity for which to generate the file name.
    /// - Returns: A string representing the full upload file name, including extension.
    func uploadFileName(for assetUploadEntity: CameraAssetUploadEntity) throws(CameraUploadFileDetailsErrorEntity) -> String
}

public extension CameraUploadFileDetailsUseCaseProtocol {
    func fileDetails(for localIdentifier: String) async throws -> CameraUploadFileDetailsEntity? {
        try await fileDetails(forLocalIdentifiers: [localIdentifier]).first
    }
}

public struct CameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCaseProtocol {
    private let cameraUploadAssetRepository: any CameraUploadAssetRepositoryProtocol
    private let cameraAssetTypeRepository: any CameraAssetTypeRepositoryProtocol
    
    @PreferenceWrapper(key: PreferenceKeyEntity.shouldConvertHEICPhoto, defaultValue: false)
    private var shouldConvertHEICPhoto: Bool
    
    private let defaultNameForMediaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public init(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol,
        cameraAssetTypeRepository: some CameraAssetTypeRepositoryProtocol,
        preferenceRepository: some PreferenceRepositoryProtocol
    ) {
        self.cameraUploadAssetRepository = cameraUploadAssetRepository
        self.cameraAssetTypeRepository = cameraAssetTypeRepository
        $shouldConvertHEICPhoto.useCase = PreferenceUseCase(repository: preferenceRepository)
    }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        try await cameraUploadAssetRepository.fileDetails(forLocalIdentifiers: identifiers)
    }
    
    public func uploadFileName(for assetUploadEntity: CameraAssetUploadEntity) throws(CameraUploadFileDetailsErrorEntity) -> String {
        let fileName = defaultNameForMediaDateFormatter.string(from: assetUploadEntity.creationDate)
        
        let extensionString = switch assetUploadEntity.mediaType {
        case .image:
            try imageExtension(for: assetUploadEntity)
        case .video:
            ".\(FileExtensionEntity.mp4.rawValue)"
        default:
            throw CameraUploadFileDetailsErrorEntity.invalidMediaType
        }
        
        return fileName + extensionString
    }
    
    private func imageExtension(for assetUploadEntity: CameraAssetUploadEntity) throws(CameraUploadFileDetailsErrorEntity) -> String {
        if assetUploadEntity.mediaSubType.contains(.photoLive) {
            return ".live.mp4"
        }
        
        guard let assetMediaType = cameraAssetTypeRepository.loadAssetType(for: assetUploadEntity.localIdentifier) else {
            throw CameraUploadFileDetailsErrorEntity.assetNotFound
        }
        
        return imageExtension(for: assetMediaType)
    }
    
    private func imageExtension(for type: AssetMediaTypeEntity) -> String {
        let prefix = type.isBurst ? ".burst" : ""
        
        let ext = switch type.mediaFormat {
        case .jpeg: FileExtensionEntity.jpg.rawValue
        case .heic: shouldConvertHEICPhoto ? FileExtensionEntity.jpg.rawValue : FileExtensionEntity.heic.rawValue
        case .heif: FileExtensionEntity.heif.rawValue
        case .png:  FileExtensionEntity.png.rawValue
        case .dng:  FileExtensionEntity.dng.rawValue
        case .gif:  FileExtensionEntity.gif.rawValue
        case .webp: FileExtensionEntity.webp.rawValue
        case .mp4:  FileExtensionEntity.mp4.rawValue
        case .mov:  FileExtensionEntity.mov.rawValue
        case .unknown(let id): id
        }
        
        return prefix + ".\(ext)"
    }
}
