import Foundation

public enum GetFavouriteNodesErrorEntity: Error {
    case generic
    case megaStore
    case sdk
    case fileManager
}
