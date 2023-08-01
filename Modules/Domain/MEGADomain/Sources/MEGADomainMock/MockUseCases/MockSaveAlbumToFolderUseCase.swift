import MEGADomain

public struct MockSaveAlbumToFolderUseCase: SaveAlbumToFolderUseCaseProtocol {
    private let saveToFolderResult: Result<[NodeEntity], Error>
    
    public init(saveToFolderResult: Result<[NodeEntity], Error> = .failure(GenericErrorEntity())) {
        self.saveToFolderResult = saveToFolderResult
    }
    
    public func saveToFolder(albumName: String,
                             photos: [NodeEntity],
                             parent: NodeEntity) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: saveToFolderResult)
        }
    }
}
