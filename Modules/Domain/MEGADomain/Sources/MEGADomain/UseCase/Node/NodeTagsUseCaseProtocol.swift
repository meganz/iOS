import Foundation

public protocol NodeTagsUseCaseProtocol: Sendable {
    func searchTags(for searchText: String?) async -> [String]?
}

public struct NodeTagsUseCase: NodeTagsUseCaseProtocol {
    private let repository: any NodeTagsRepositoryProtocol

    public init(repository: some NodeTagsRepositoryProtocol) {
        self.repository = repository
    }
    
    public func searchTags(for searchText: String?) async -> [String]? {
        await repository.searchTags(for: searchText)
    }
}
