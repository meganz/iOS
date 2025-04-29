import Foundation
import MEGADomain

public final class MockMetadataUseCase: MetadataUseCaseProtocol {
    private let formattedCoordinate: String?
    private let coordinate: Coordinate?
    
    public init(
        formattedCoordinate: String? = nil,
        coordinate: Coordinate? = nil
    ) {
        self.formattedCoordinate = formattedCoordinate
        self.coordinate = coordinate
    }
    
    public func formattedCoordinate(forFileURL url: URL) async -> String? {
        formattedCoordinate
    }
    
    public func formattedCoordinate(forFilePath path: String) async -> String? {
        formattedCoordinate
    }
    
    public func formattedCoordinate(for coordinate: Coordinate) -> String {
        formattedCoordinate ?? ""
    }
    
    public func coordinateInTheFile(at url: URL) async -> Coordinate? {
        coordinate
    }
    
    public func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws { }
}
