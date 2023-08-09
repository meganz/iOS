import Combine
import MEGADomain

public final class MockNodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: MockNodeTransferRepository = MockNodeTransferRepository()
    
    public let transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never>
    public var registerMEGATransferDelegateCalled = 0
    public var deRegisterMEGATransferDelegateCalled = 0
    public var registerMEGASharedFolderTransferDelegateCalled = 0
    public var deRegisterMEGASharedFolderTransferDelegateCalled = 0
    
    public init(transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> = Empty().eraseToAnyPublisher()) {
        self.transferResultPublisher = transferResultPublisher
    }
    
    public func registerMEGATransferDelegate() async {
        registerMEGATransferDelegateCalled += 1
    }
    
    public func deRegisterMEGATransferDelegate() async {
        deRegisterMEGATransferDelegateCalled += 1
    }
    
    public func registerMEGASharedFolderTransferDelegate() async {
        registerMEGASharedFolderTransferDelegateCalled += 1
    }
    
    public func deRegisterMEGASharedFolderTransferDelegate() async {
        deRegisterMEGASharedFolderTransferDelegateCalled += 1
    }
}
