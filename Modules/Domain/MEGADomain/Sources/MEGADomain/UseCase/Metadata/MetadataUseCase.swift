import Foundation
import MEGASwift

public protocol MetadataUseCaseProtocol: Sendable {
    func formattedCoordinate(forFileURL url: URL) async -> String?
    func formattedCoordinate(forFilePath path: String) async -> String?
    func formattedCoordinate(for coordinate: Coordinate) -> String
    func coordinateInTheFile(at url: URL) async -> Coordinate?
    func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws
}

public final class MetadataUseCase: MetadataUseCaseProtocol {
    private let metadataRepository: any MetadataRepositoryProtocol
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    private let fileExtensionRepository: any FileExtensionRepositoryProtocol
    private let nodeCoordinatesRepository: any NodeCoordinatesRepositoryProtocol

    public init(
        metadataRepository: some MetadataRepositoryProtocol,
        fileSystemRepository: some FileSystemRepositoryProtocol,
        fileExtensionRepository: some FileExtensionRepositoryProtocol,
        nodeCoordinatesRepository: some NodeCoordinatesRepositoryProtocol
    ) {
        self.metadataRepository = metadataRepository
        self.fileSystemRepository = fileSystemRepository
        self.fileExtensionRepository = fileExtensionRepository
        self.nodeCoordinatesRepository = nodeCoordinatesRepository
    }

    public func formattedCoordinate(forFileURL url: URL) async -> String? {
        guard let coordinate = await coordinateInTheFile(at: url) else { return nil }
        return formattedCoordinate(for: coordinate)
    }
    
    public func formattedCoordinate(forFilePath path: String) async -> String? {
        let url = if path.contains("/tmp/") {
            URL(fileURLWithPath: path)
        } else {
            URL(fileURLWithPath: NSHomeDirectory().append(pathComponent: path))
        }
        return await formattedCoordinate(forFileURL: url)
    }
    
    public func formattedCoordinate(for coordinate: Coordinate) -> String {
        metadataRepository.formatCoordinate(coordinate)
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
    
    public func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws {
        try await nodeCoordinatesRepository.setUnshareableNodeCoordinates(node, latitude: latitude, longitude: longitude)
    }
}
