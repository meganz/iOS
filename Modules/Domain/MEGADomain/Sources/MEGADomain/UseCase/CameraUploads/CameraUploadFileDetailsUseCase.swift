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
}

public extension CameraUploadFileDetailsUseCaseProtocol {
    func fileDetails(for localIdentifier: String) async throws -> CameraUploadFileDetailsEntity? {
        try await fileDetails(forLocalIdentifiers: [localIdentifier]).first
    }
}

public struct CameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCaseProtocol {
    private let cameraUploadAssetRepository: any CameraUploadAssetRepositoryProtocol
    
    public init(cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol) {
        self.cameraUploadAssetRepository = cameraUploadAssetRepository
    }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        try await cameraUploadAssetRepository.fileDetails(forLocalIdentifiers: identifiers)
    }
}
