import Foundation

public protocol MetadataUseCaseProtocol: Sendable {
    func coordinateInTheFile(at url: URL) async -> Coordinate?
    func formatCoordinate(_ coordinate: Coordinate) -> String
}

public final class MetadataUseCase: MetadataUseCaseProtocol {
    private let metadataRepository: any MetadataRepositoryProtocol
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    private let fileExtensionRepository: any FileExtensionRepositoryProtocol

    public init(
        metadataRepository: some MetadataRepositoryProtocol,
        fileSystemRepository: some FileSystemRepositoryProtocol,
        fileExtensionRepository: some FileExtensionRepositoryProtocol
    ) {
        self.metadataRepository = metadataRepository
        self.fileSystemRepository = fileSystemRepository
        self.fileExtensionRepository = fileExtensionRepository
    }

    public func coordinateInTheFile(at url: URL) async -> Coordinate? {
        guard fileSystemRepository.fileExists(at: url) else { return nil }

        if fileExtensionRepository.isImage(url: url) {
            return metadataRepository.coordinateForImage(at: url)
        } else if fileExtensionRepository.isVideo(url: url) {
            return await metadataRepository.coordinateForVideo(at: url)
        }

        return nil
    }

    public func formatCoordinate(_ coordinate: Coordinate) -> String {
        metadataRepository.formatCoordinate(coordinate)
    }
}
