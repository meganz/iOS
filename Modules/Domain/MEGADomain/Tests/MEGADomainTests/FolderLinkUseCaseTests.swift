import MEGADomain
import MEGADomainMock
import Testing

@Suite("FolderLinkUseCase Tests")
struct FolderLinkUseCaseTests {
    @Test("Completed download transfer")
    func shouldYieldUpdates() async {
        let transferEntities = [
            TransferEntity(type: .upload, nodeHandle: 1),
            TransferEntity(type: .download, nodeHandle: 2, isStreamingTransfer: true),
            TransferEntity(type: .download, nodeHandle: 3, isStreamingTransfer: false)
        ]
        
        let transferRepository = MockTransferRepository(completedTransfers: transferEntities)
        let sut = FolderLinkUseCase(transferRepository: transferRepository)
        
        var handles: [HandleEntity] = []
        for await handle in sut.completedDownloadTransferUpdates {
            handles.append(handle)
        }
        
        #expect(handles == [3])
    }
}
