import Foundation

public enum NodeTagsUpdateError: Error {
    case invalidArguments
    case alreadyExists
    case doesNotExist
    case businessPastDue
    case nodeNotFound
    case generic
}
