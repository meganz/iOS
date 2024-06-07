import Foundation

enum SensitiveContentAcknowledgementStatus {
    ///  Unknown whether not the context contains any sensitive elements. Should trigger a request to fetch this information.
    case unknown
    /// User has not determined if they allow further operations on the given context. Should present alert to get users approval.
    case notDetermined
    /// Context contains no sensitive data, therefore requires no approval from user
    case noSensitiveContent
    /// User has given consent to continue action on sensitive content
    case authorized
    /// User has rejected consent to continue action on sensitive content, further action should halt and exit.
    case denied
}
