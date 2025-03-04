import Foundation
import MEGADomain

public final class MockMetadataRepository: MetadataRepositoryProtocol, @unchecked Sendable {
    public enum Action: Equatable {
        case coordinateForImage(URL)
        case coordinateForVideo(URL)
        case formatCoordinate(Coordinate)
    }

    public var actions = [Action]()
    let coordinate: Coordinate?
    let formattedString: String

    public init(
        coordinate: Coordinate? = nil,
        formattedString: String = ""
    ) {
        self.coordinate = coordinate
        self.formattedString = formattedString
    }

    public func coordinateForImage(at url: URL) -> Coordinate? {
        actions.append(.coordinateForImage(url))
        return coordinate
    }

    public func coordinateForVideo(at url: URL) async -> Coordinate? {
        actions.append(.coordinateForVideo(url))
        return coordinate
    }

    public func formatCoordinate(_ coordinate: Coordinate) -> String {
        actions.append(.formatCoordinate(coordinate))
        return formattedString
    }
}
