import Foundation

public protocol NodeFavouriteActionUseCaseProtocol: Sendable {
    func favourite(node: NodeEntity) async throws
    func unFavourite(node: NodeEntity) async throws
    /// Sets the favourite state for every node with bounded concurrency. Every node is attempted (best
    /// effort) and the first failure, if any, is thrown once all requests finish.
    func favourite(nodes: [NodeEntity], isFavourite: Bool) async throws
}

public struct NodeFavouriteActionUseCase<T: NodeFavouriteActionRepositoryProtocol>: NodeFavouriteActionUseCaseProtocol {

    /// Caps concurrent favourite requests as required by the Swift Concurrency guide.
    private static var maxConcurrentActions: Int { 3 }

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

    public func favourite(nodes: [NodeEntity], isFavourite: Bool) async throws {
        let firstFailure = await withTaskGroup(of: Result<Void, any Error>.self) { group -> (any Error)? in
            var iterator = nodes.makeIterator()

            for _ in 0..<min(Self.maxConcurrentActions, nodes.count) {
                guard let node = iterator.next() else { break }
                group.addTask { await settingFavourite(isFavourite, for: node) }
            }

            var firstFailure: (any Error)?
            while let result = await group.next() {
                if case .failure(let error) = result, firstFailure == nil {
                    firstFailure = error
                }
                if let node = iterator.next() {
                    group.addTask { await settingFavourite(isFavourite, for: node) }
                }
            }
            return firstFailure
        }

        if let firstFailure {
            throw firstFailure
        }
    }

    private func settingFavourite(_ isFavourite: Bool, for node: NodeEntity) async -> Result<Void, any Error> {
        do {
            if isFavourite {
                try await nodeFavouriteRepository.favourite(node: node)
            } else {
                try await nodeFavouriteRepository.unFavourite(node: node)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
