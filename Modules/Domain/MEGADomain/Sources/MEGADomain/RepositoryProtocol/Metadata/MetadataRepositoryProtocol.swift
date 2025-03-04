import Foundation

public protocol MetadataRepositoryProtocol: Sendable {
    func coordinateForImage(at url: URL) -> Coordinate?
    func coordinateForVideo(at url: URL) async -> Coordinate?
    func formatCoordinate(_ coordinate: Coordinate) -> String
}
