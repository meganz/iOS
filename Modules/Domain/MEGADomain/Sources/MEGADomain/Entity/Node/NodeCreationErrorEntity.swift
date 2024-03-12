import Foundation

public enum NodeCreationErrorEntity: Error {
    case nodeNotFound
    case nodeAlreadyExists
    case nodeCreationFailed
    case nodeCreatedButCannotBeSearched
}
