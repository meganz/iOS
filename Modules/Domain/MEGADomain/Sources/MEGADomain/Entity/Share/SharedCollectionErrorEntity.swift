public enum SharedCollectionErrorEntity: Error {
    case resourceNotFound
    case couldNotBeReadOrDecrypted
    case malformed
    case permissionError
}
