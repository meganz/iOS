import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("TransferCounterUseCase Tests")
struct TransferCounterUseCaseTests {
    
    private static let regularTransfer = TransferEntity(type: .upload)
    private static let streamingTransfer = TransferEntity(isStreamingTransfer: true)
    private static let folderTransfer = TransferEntity(isFolderTransfer: true)
    private static let regularResponse = makeTransferResponseEntity(isStreamingTransfer: false, isFolderTransfer: false)
    private static let streamingResponse = makeTransferResponseEntity(isStreamingTransfer: true, isFolderTransfer: false)
    private static let folderResponse = makeTransferResponseEntity(isStreamingTransfer: false, isFolderTransfer: true)
    
    // MARK: - Test Data Factory
    
    private static func makeTransferResponseEntity(
        isStreamingTransfer: Bool = false,
        isFolderTransfer: Bool = false
    ) -> TransferResponseEntity {
        let transferEntity = TransferEntity(
            type: .upload,
            isStreamingTransfer: isStreamingTransfer,
            isFolderTransfer: isFolderTransfer
        )
        let errorEntity = ErrorEntity(type: .ok) // Assuming this structure
        return TransferResponseEntity(transferEntity: transferEntity, error: errorEntity)
    }
    
    private static func makeSUT(mockRepo: MockNodeTransferRepository) -> any TransferCounterUseCaseProtocol {
        let mockTransferInventoryRepo = MockTransferInventoryRepository.newRepo
        let mockFileSystemRepo = MockFileSystemRepository.sharedRepo
        let useCase = TransferCounterUseCase(repo: mockRepo, transferInventoryRepository: mockTransferInventoryRepo, fileSystemRepository: mockFileSystemRepo)
        return useCase
    }
    
    // MARK: - transferStartUpdates Tests
    
    @Suite("TransferStartUpdates Tests")
    struct TransferStartUpdatesTests {
        @Test("transferStartUpdates filters out streaming transfers")
        func transferStartUpdatesFiltersStreamingTransfers() async throws {
            // Given
            let updates: [TransferEntity] = [regularTransfer, streamingTransfer]
            let mockRepo = MockNodeTransferRepository(transferStartUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // when
            var receivedTransfers: [TransferEntity] = []
            for await transfer in useCase.transferStartUpdates {
                receivedTransfers.append(transfer)
            }
            
            // Then
            #expect(receivedTransfers.count == 1)
        }
        
        @Test("transferStartUpdates filters out folder transfers")
        func transferStartUpdatesFiltersFolderTransfers() async throws {
            // Given
            let updates: [TransferEntity] = [regularTransfer, folderTransfer]
            let mockRepo = MockNodeTransferRepository(transferStartUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            
            var receivedTransfers: [TransferEntity] = []
            for await transfer in useCase.transferStartUpdates {
                receivedTransfers.append(transfer)
            }
            
            // Then
            #expect(receivedTransfers.count == 1)
        }
        
        @Test("transferStartUpdates filters out both streaming and folder transfers")
        func transferStartUpdatesFiltersBothStreamingAndFolderTransfers() async throws {
            // Given
            let streamingFolderTransfer = TransferEntity(type: .upload, isStreamingTransfer: true, isFolderTransfer: true)
            let updates: [TransferEntity] = [regularTransfer, streamingFolderTransfer]
            let mockRepo = MockNodeTransferRepository(transferStartUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedTransfers: [TransferEntity] = []
            for await transfer in useCase.transferStartUpdates {
                receivedTransfers.append(transfer)
            }
            
            // Then
            #expect(receivedTransfers.count == 1)
        }
    }
    
    // MARK: - transferUpdates Tests
    
    @Suite("TransferUpdates Tests")
    struct TransferUpdatesTests {
        @Test("transferUpdates filters out streaming transfers")
        func transferUpdatesFiltersStreamingTransfers() async throws {
            // Given
            let updates: [TransferEntity] = [regularTransfer, streamingTransfer]
            let mockRepo = MockNodeTransferRepository(transferUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedTransfers: [TransferEntity] = []
            for await transfer in useCase.transferUpdates {
                receivedTransfers.append(transfer)
            }
            
            // Then
            #expect(receivedTransfers.count == 1)
        }
        
        @Test("transferUpdates filters out folder transfers")
        func transferUpdatesFiltersFolderTransfers() async throws {
            // Given
            let updates: [TransferEntity] = [regularTransfer, folderTransfer]
            let mockRepo = MockNodeTransferRepository(transferUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedTransfers: [TransferEntity] = []
            for await transfer in useCase.transferUpdates {
                receivedTransfers.append(transfer)
            }
            
            // Then
            #expect(receivedTransfers.count == 1)
        }
    }
    
    // MARK: - transferTemporaryErrorUpdates Tests
    
    @Suite("TransferTemporaryErrorUpdates Tests")
    struct TransferTemporaryErrorUpdatesTests {
        @Test("transferTemporaryErrorUpdates filters out streaming transfers")
        func transferTemporaryErrorUpdatesFiltersStreamingTransfers() async throws {
            // Given
            let updates: [TransferResponseEntity] = [regularResponse, streamingResponse]
            let mockRepo = MockNodeTransferRepository(transferTemporaryErrorUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedResponses: [TransferResponseEntity] = []
            for await response in useCase.transferTemporaryErrorUpdates {
                receivedResponses.append(response)
            }
            
            // Then
            #expect(receivedResponses.count == 1)
        }
        
        @Test("transferTemporaryErrorUpdates filters out folder transfers")
        func transferTemporaryErrorUpdatesFiltersFolderTransfers() async throws {
            // Given
            let updates: [TransferResponseEntity] = [regularResponse, folderResponse]
            let mockRepo = MockNodeTransferRepository(transferTemporaryErrorUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedResponses: [TransferResponseEntity] = []
            for await response in useCase.transferTemporaryErrorUpdates {
                receivedResponses.append(response)
            }
            
            // Then
            #expect(receivedResponses.count == 1)
        }
    }
    
    // MARK: - transferFinishUpdates Tests
    
    @Suite("TransferFinishUpdates Tests")
    struct TransferFinishUpdatesTests {
        @Test("transferFinishUpdates filters out streaming transfers")
        func transferFinishUpdatesFiltersStreamingTransfers() async throws {
            // Given
            let updates: [TransferResponseEntity] = [regularResponse, streamingResponse]
            let mockRepo = MockNodeTransferRepository(transferFinishUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedResponses: [TransferResponseEntity] = []
            for await response in useCase.transferFinishUpdates {
                receivedResponses.append(response)
            }
            
            // Then
            #expect(receivedResponses.count == 1)
        }
        
        @Test("transferFinishUpdates filters out folder transfers")
        func transferFinishUpdatesFiltersFolderTransfers() async throws {
            // Given
            let updates: [TransferResponseEntity] = [regularResponse, folderResponse]
            let mockRepo = MockNodeTransferRepository(transferFinishUpdates: updates.async.eraseToAnyAsyncSequence())
            let useCase = makeSUT(mockRepo: mockRepo)
            
            // When
            var receivedResponses: [TransferResponseEntity] = []
            for await response in useCase.transferFinishUpdates {
                receivedResponses.append(response)
            }
            
            // Then
            #expect(receivedResponses.count == 1)
        }
    }
}
