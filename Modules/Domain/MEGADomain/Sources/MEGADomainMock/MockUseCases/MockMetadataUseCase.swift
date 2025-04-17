import Foundation
import MEGADomain

public final class MockMetadataUseCase: MetadataUseCaseProtocol {
    private let formattedCoordinate: String?
    
    public init(formattedCoordinate: String? = nil) {
        self.formattedCoordinate = formattedCoordinate
    }
    
    public func formattedCoordinate(forFileURL url: URL) async -> String? {
        formattedCoordinate
    }
    
    public func formattedCoordinate(forFilePath path: String) async -> String? {
        formattedCoordinate
    }
}
