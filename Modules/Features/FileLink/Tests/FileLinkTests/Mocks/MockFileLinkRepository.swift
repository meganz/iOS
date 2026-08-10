import FileLink
import MEGADomain

struct MockFileLinkRepository: FileLinkRepositoryProtocol {
    static var newRepo: MockFileLinkRepository { MockFileLinkRepository() }

    private let result: Result<NodeEntity, FileLinkPublicNodeErrorEntity>

    init(result: Result<NodeEntity, FileLinkPublicNodeErrorEntity> = .success(NodeEntity(handle: 1))) {
        self.result = result
    }

    func publicNode(for link: String) async throws(FileLinkPublicNodeErrorEntity) -> NodeEntity {
        try result.get()
    }
}
