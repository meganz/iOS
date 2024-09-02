import Foundation

public protocol PublicCollectionUseCaseProtocol: Sendable {
    func publicCollection(forLink link: String) async throws -> SharedCollectionEntity
    func publicNodes(_ elements: [SetElementEntity]) async -> [NodeEntity]
    func stopCollectionLinkPreview()
}

public struct PublicCollectionUseCase<S: ShareCollectionRepositoryProtocol>: PublicCollectionUseCaseProtocol {
    private let shareCollectionRepository: S
    
    public init(shareCollectionRepository: S) {
        self.shareCollectionRepository = shareCollectionRepository
    }
    
    public func publicCollection(forLink link: String) async throws -> SharedCollectionEntity {
        try await shareCollectionRepository.publicCollectionContents(forLink: link)
    }
    
    public func publicNodes(_ elements: [SetElementEntity]) async -> [NodeEntity] {
        return await withTaskGroup(of: NodeEntity?.self) { group in
            elements.forEach { element in
                group.addTask {
                    try? await shareCollectionRepository.publicNode(element)
                }
            }
            return await group.reduce(into: [NodeEntity]()) {
                if let node = $1 { $0.append(node) }
            }
        }
    }
    
    public func stopCollectionLinkPreview() {
        shareCollectionRepository.stopCollectionLinkPreview()
    }
}
