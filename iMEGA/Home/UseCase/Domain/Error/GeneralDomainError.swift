import Foundation

enum DomainError: Error {

    case nodeNotFound

    case sdkError(MEGASDKErrorType)

    // MARK: - NodeLabelActionUseCaseProtocol

    case unsupportedNodeLabelColorFound
}
