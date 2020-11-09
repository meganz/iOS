import Foundation

enum GetSMSErrorEntity: Error, CaseIterable {
    case generic
    case failedToGetCallingCodes
}
