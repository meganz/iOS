import Foundation

struct PreviewLoading: AsyncSequence {
    typealias Element = URL
    
    let types: [ThumbnailTypeEntity]
    let node: NodeEntity
    let repo: ThumbnailRepositoryProtocol
    
    func makeAsyncIterator() -> PreviewLoadingIterator {
        PreviewLoadingIterator(types: types,  node: node, repo: repo)
    }
}

struct PreviewLoadingIterator: AsyncIteratorProtocol {
    var index = 0
    var types: [ThumbnailTypeEntity]
    var node: NodeEntity
    var repo: ThumbnailRepositoryProtocol
    
    mutating func next() async throws -> URL? {
        guard index < types.count else {
            return nil
        }
        
        let type = types[index]
        
        if type == .thumbnail && !repo.hasCachedPreview(for: node) {
            index += 1
            
            do {
                return try await repo.loadThumbnail(for: node)
            } catch {
                index += 1
                return try await repo.loadPreview(for: node)
            }
        } else {
            index += 2
            
            do {
                return try await repo.loadPreview(for: node)
            } catch {
                return nil
            }
        }
    }
}
