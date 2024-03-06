import Foundation

public protocol MetadataRepositoryProtocol {
    func coordinateForImage(at url: URL) -> Coordinate?
    func coordinateForVideo(at url: URL) -> Coordinate?
    func formatCoordinate(_ coordinate: Coordinate) -> String
}
