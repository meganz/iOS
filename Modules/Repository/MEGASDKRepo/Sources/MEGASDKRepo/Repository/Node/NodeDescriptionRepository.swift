import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeDescriptionRepository: NodeDescriptionRepositoryProtocol {
    public static var newRepo: NodeDescriptionRepository {
        NodeDescriptionRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func update(description: String?, for node: NodeEntity) async throws -> NodeEntity {
        guard let megaNode = node.toMEGANode(in: sdk) else {
            throw NodeDescriptionErrorEntity.nodeNotFound
        }

        return try await withAsyncThrowingValue { completion in
            sdk.setDescription(description, for: megaNode, delegate: RequestDelegate { result  in
                switch result {
                case .failure:
                    completion(.failure(NodeDescriptionErrorEntity.failed))
                case .success(let request):
                    completion(.init { try updatedNode(for: node) })
                }
            })
        }
    }

    private func updatedNode(for node: NodeEntity) throws -> NodeEntity {
        guard let node = sdk.node(forHandle: node.handle) else {
            throw NodeDescriptionErrorEntity.nodeNotFound
        }

        return node.toNodeEntity()
    }
}
