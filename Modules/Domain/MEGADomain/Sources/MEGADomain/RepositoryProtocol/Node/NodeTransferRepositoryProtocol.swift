import Combine
import Foundation

public protocol NodeTransferRepositoryProtocol: RepositoryProtocol {
    var transferResultPublisher: AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> { get }
    func registerMEGATransferDelegate() async
    func deRegisterMEGATransferDelegate() async
    func registerMEGASharedFolderTransferDelegate() async
    func deRegisterMEGASharedFolderTransferDelegate() async
}
