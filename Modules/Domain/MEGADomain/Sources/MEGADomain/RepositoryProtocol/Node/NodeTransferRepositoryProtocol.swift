import Foundation
import MEGASwift

public protocol NodeTransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var transferFinishUpdates: AnyAsyncSequence<Result<TransferEntity, ErrorEntity>> { get }
}
