import Foundation

public protocol NodeFavouriteActionUseCaseProtocol: Sendable {
    func favourite(node: NodeEntity) async throws
    func unFavourite(node: NodeEntity) async throws
}

public struct NodeFavouriteActionUseCase<T: NodeFavouriteActionRepositoryProtocol>: NodeFavouriteActionUseCaseProtocol {

    private let nodeFavouriteRepository: T

    public init(nodeFavouriteRepository: T) {
        self.nodeFavouriteRepository = nodeFavouriteRepository
    }

    public func favourite(node: NodeEntity) async throws {
        try await nodeFavouriteRepository.favourite(node: node)
    }

    public func unFavourite(node: NodeEntity) async throws {
        try await nodeFavouriteRepository.unFavourite(node: node)
    }
}
