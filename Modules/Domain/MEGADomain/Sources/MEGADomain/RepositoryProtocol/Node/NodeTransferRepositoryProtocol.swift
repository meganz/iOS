import Foundation
import MEGASwift

public protocol NodeTransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var nodeTransferCompletionUpdates: AnyAsyncSequence<TransferEntity> { get }
}
