import MEGADomain
import Search
import SwiftUI

public enum LinkUnavailableReason: Error, Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}

public protocol FolderLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

public protocol FolderLinkSearchResultMapperProtocol: Sendable {
    func mapToSearchResult(from node: NodeEntity) -> SearchResult
}

@MainActor
public protocol FolderLinkFileNodeOpenerProtocol: Sendable {
    func openNode(handle: HandleEntity, siblings: [HandleEntity])
}
