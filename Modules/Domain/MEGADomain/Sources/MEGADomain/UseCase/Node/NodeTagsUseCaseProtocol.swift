import Foundation
import MEGASwift

public protocol NodeTagsUseCaseProtocol: Sendable {
    func searchTags(for searchText: String?) async -> [String]?
    func getTags(for node: NodeEntity) async -> [String]?
    func add(tag: String, to node: NodeEntity) async throws
    func remove(tag: String, from node: NodeEntity) async throws
}

public struct NodeTagsUseCase: NodeTagsUseCaseProtocol {
    private let repository: any NodeTagsRepositoryProtocol

    public init(repository: some NodeTagsRepositoryProtocol) {
        self.repository = repository
    }
    
    public func searchTags(for searchText: String?) async -> [String]? {
        await repository.searchTags(for: searchText)
    }

    public func getTags(for node: NodeEntity) async -> [String]? {
        await repository.getTags(for: node)
    }

    public func add(tag: String, to node: NodeEntity) async throws {
        try await repository.add(tag: tag, to: node)
    }

    public func remove(tag: String, from node: NodeEntity) async throws {
        try await repository.remove(tag: tag, from: node)
    }
}
