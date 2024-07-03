import Combine
import MEGADomain
import MEGASwift

public final class MockNodeTransferRepository: NodeTransferRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockNodeTransferRepository = MockNodeTransferRepository()
    
    public let transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never>
    @Atomic public var registerMEGATransferDelegateCalled = 0
    @Atomic public var deRegisterMEGATransferDelegateCalled = 0
    @Atomic public var registerMEGASharedFolderTransferDelegateCalled = 0
    @Atomic public var deRegisterMEGASharedFolderTransferDelegateCalled = 0
    
    public init(transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> = Empty().eraseToAnyPublisher()) {
        self.transferResultPublisher = transferResultPublisher
    }
    
    public func registerMEGATransferDelegate() async {
        $registerMEGATransferDelegateCalled.mutate { $0 += 1 }
    }
    
    public func deRegisterMEGATransferDelegate() async {
        $deRegisterMEGATransferDelegateCalled.mutate { $0 += 1 }
    }
    
    public func registerMEGASharedFolderTransferDelegate() async {
        $registerMEGASharedFolderTransferDelegateCalled.mutate { $0 += 1 }
    }
    
    public func deRegisterMEGASharedFolderTransferDelegate() async {
        $deRegisterMEGASharedFolderTransferDelegateCalled.mutate { $0 += 1 }
    }
}
