

enum UserImageLoadErrorEntity: Error {
    case generic
    case base64EncodingError
    case unableToFetch
    case timeout
    case unableToCreateImage
}
