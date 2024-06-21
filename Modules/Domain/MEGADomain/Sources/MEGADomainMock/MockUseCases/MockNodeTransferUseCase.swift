import Combine
import Foundation
import MEGADomain

public struct MockNodeTransferUseCase: NodeTransferUseCaseProtocol {

    private let _transferResult: Result<TransferEntity, TransferErrorEntity>

    public init(
        _transferResult: Result<TransferEntity, TransferErrorEntity> = .failure(.cancelled)
    ) {
        self._transferResult = _transferResult
    }

    public func transferResultPublisher() -> AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> {
        Just(_transferResult)
            .eraseToAnyPublisher()
    }

    public func registerMEGATransferDelegate() async {}

    public func deRegisterMEGATransferDelegate() async {}

    public func registerMEGASharedFolderTransferDelegate() async {}

    public func deRegisterMEGASharedFolderTransferDelegate() async {}
}
