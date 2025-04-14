import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("Transfer UseCase Test Suite - Testing transfer download, upload, and cancellation")
struct TransferUseCaseTestSuite {
    private static let testNode = NodeEntity(handle: 1234)
    private static let testParent = NodeEntity(handle: 12345)
    private static let downloadUrl = URL(fileURLWithPath: "/path")
    private static let uploadUrl = URL(fileURLWithPath: "/path/file.txt")
    private static let stubbedDownload = TransferEntity(type: .download, path: downloadUrl.path, nodeHandle: testNode.handle)
    private static let stubbedUpload = TransferEntity(type: .upload, path: uploadUrl.path, parentHandle: testParent.handle)
    
    private static func makeSUT(
        stubbedDownloadTransfer: TransferEntity? = stubbedDownload,
        stubbedUploadTransfer: TransferEntity? = stubbedUpload,
        downloadError: (any Error)? = nil,
        uploadError: (any Error)? = nil
    ) -> (TransferUseCase<MockTransferRepository>, MockTransferRepository) {
        let repo = MockTransferRepository(
            stubbedDownloadTransfer: stubbedDownloadTransfer,
            stubbedUploadTransfer: stubbedUploadTransfer,
            downloadError: downloadError,
            uploadError: uploadError
        )
        return (TransferUseCase(repo: repo), repo)
    }
    
    @Suite("Download Tests")
    @MainActor
    struct DownloadTests {
        @Test("Download returns correct transfer entity")
        static func downloadSuccess() async throws {
            let (sut, _) = TransferUseCaseTestSuite.makeSUT()
            let transfer = try await sut.download(
                node: TransferUseCaseTestSuite.testNode,
                to: TransferUseCaseTestSuite.downloadUrl,
                collisionResolution: .renameNewWithSuffix
            )
            #expect(TransferUseCaseTestSuite.testNode.handle == transfer.nodeHandle, "Expected node handle to match")
            #expect(TransferUseCaseTestSuite.downloadUrl.path == transfer.path, "Expected path to match")
        }
        
        @Test("Download should throw error when repository error is set")
        static func downloadFailure() async {
            let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
            let (sut, _) = TransferUseCaseTestSuite.makeSUT(downloadError: expectedError)
            
            await #expect(performing: {
                try await sut.download(
                    node: TransferUseCaseTestSuite.testNode,
                    to: TransferUseCaseTestSuite.downloadUrl,
                    collisionResolution: .renameNewWithSuffix,
                    startHandler: nil,
                    progressHandler: nil
                )
            }, throws: { error in
                (error as NSError).code == 1
            })
        }
    }
    
    @Suite("Upload Tests")
    @MainActor
    struct UploadTests {
        @Test("Upload returns correct transfer entity")
        static func uploadSuccess() async throws {
            let (sut, _) = TransferUseCaseTestSuite.makeSUT()
            let transfer = try await sut.uploadFile(
                at: TransferUseCaseTestSuite.uploadUrl,
                to: TransferUseCaseTestSuite.testParent,
                startHandler: nil,
                progressHandler: nil
            )
            #expect(TransferUseCaseTestSuite.testParent.handle == transfer.parentHandle, "Expected parent handle to match")
            #expect(TransferUseCaseTestSuite.uploadUrl.path == transfer.path, "Expected path to match file URL path")
        }
        
        @Test("Upload should throw error when repository error is set")
        static func uploadFailure() async {
            let expectedError = NSError(domain: "TestDomain", code: 2, userInfo: nil)
            let (sut, _) = TransferUseCaseTestSuite.makeSUT(uploadError: expectedError)
            
            await #expect(performing: {
                try await sut.uploadFile(
                    at: TransferUseCaseTestSuite.uploadUrl,
                    to: TransferUseCaseTestSuite.testParent,
                    startHandler: nil,
                    progressHandler: nil
                )
            }, throws: { error in
                (error as NSError).code == 2
            })
        }
    }
    
    @Suite("Cancel Tests")
    @MainActor
    struct CancelTests {
        @Test("Cancel Download Transfers increments counter")
        static func cancelDownloadIncrements() async throws {
            let (sut, repo) = makeSUT()
            try await sut.cancelDownloadTransfers()
            #expect(repo.cancelDownloadTransfers_calledTimes == 1, "Expected cancelDownloadTransfers to be called once")
        }
        
        @Test("Cancel Upload Transfers increments counter")
        static func cancelUploadIncrements() async throws {
            let (sut, repo) = makeSUT()
            try await sut.cancelUploadTransfers()
            #expect(repo.cancelUploadTransfers_calledTimes == 1, "Expected cancelUploadTransfers to be called once")
        }
    }
}
