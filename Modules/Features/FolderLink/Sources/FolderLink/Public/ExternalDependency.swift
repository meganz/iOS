import MEGADomain
import Search
import SwiftUI
import UIKit

public enum LinkUnavailableReason: Error, Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}

public struct FolderLinkNodeAction {
    public let handle: HandleEntity
    public let sender: UIButton
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

@MainActor
public protocol FolderLinkNodeActionHandlerProtocol: Sendable {
    func handle(action: FolderLinkNodeAction)
}
