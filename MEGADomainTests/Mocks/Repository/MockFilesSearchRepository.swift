@testable import MEGA

final class MockFilesSearchRepository: FilesSearchRepositoryProtocol {
    var imageNodes: [MEGANode] = []
    var videoNodes: [MEGANode] = []
    var megaNodeFormatType: MEGANodeFormatType = .audio
    
    static var newRepo: MockFilesSearchRepository {
        MockFilesSearchRepository()
    }
    
    func search(string: String?, inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void) {
        completionBlock(nil, false)
    }
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType) async throws -> [MEGANode] {
        formatType == .photo ? imageNodes : videoNodes
    }
    
    func megaNodeFormatType(from explorerType: ExplorerTypeEntity) -> MEGANodeFormatType {
        megaNodeFormatType
    }
    
    func cancelSearch() {}
}
