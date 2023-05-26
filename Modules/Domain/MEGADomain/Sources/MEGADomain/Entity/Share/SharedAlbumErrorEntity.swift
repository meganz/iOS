import Foundation

public enum SharedAlbumErrorEntity: Error {
    case resourceNotFound
    case couldNotBeReadOrDecrypted
    case malformed
    case permissionError
}
