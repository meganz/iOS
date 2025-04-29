import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeCoordinatesRepository: NodeCoordinatesRepositoryProtocol {
    public static var newRepo: NodeCoordinatesRepository {
        NodeCoordinatesRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws {
        return try await withAsyncThrowingValue { completion in
            guard let megaNode = sdk.node(forHandle: node.handle) else {
                completion(.failure(GenericErrorEntity()))
                return
            }
            sdk.setUnshareableNodeCoordinates(megaNode, latitude: latitude, longitude: longitude, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }
}
