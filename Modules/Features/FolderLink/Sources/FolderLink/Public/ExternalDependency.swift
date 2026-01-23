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

public enum FolderLinkNodesAction {
    case addToCloudDrive(Set<HandleEntity>)
    case makeAvailableOffline(Set<HandleEntity>)
    case sendToChat(String)
    case saveToPhotos(Set<HandleEntity>)
}

public protocol FolderLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

public protocol FolderLinkSearchResultMapperProtocol: Sendable {
    func mapToSearchResult(from node: NodeEntity) -> SearchResult
}

@MainActor
public protocol FolderLinkFileNodeOpenerProtocol {
    func openNode(handle: HandleEntity, siblings: [HandleEntity])
}

@MainActor
public protocol FolderLinkNodeActionHandlerProtocol {
    func handle(action: FolderLinkNodeAction)
    func handle(action: FolderLinkNodesAction)
}

@MainActor
public protocol FolderLinkMediaDiscoveryContentBuilderProtocol {
    associatedtype Content: View
    
    func build(viewModel: FolderLinkMediaDiscoveryViewModel) -> Content
}

public protocol FolderLinkMediaDiscoveryContent: View {
    init(viewModel: FolderLinkMediaDiscoveryViewModel)
}
