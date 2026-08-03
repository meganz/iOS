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
    /// Called when the Select row of the node's action sheet is picked. Selection belongs to the folder
    /// link itself rather than to the sheet, so the sheet hands it back instead of acting on it.
    public let selectHandler: @MainActor () -> Void
}

public enum FolderLinkNodesAction: Equatable {
    case addToCloudDrive(Set<HandleEntity>)
    case makeAvailableOffline(Set<HandleEntity>)
    case sendToChat(String)
    case saveToPhotos(Set<HandleEntity>)
}

public protocol FolderLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

public protocol FolderLinkSearchResultsProvidingBuilderProtocol: Sendable {
    func build(with handle: HandleEntity) -> any SearchResultsProviding
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

@MainActor
public protocol FolderLinkLogoutPolicyProtocol {
    func shouldLogoutUponFolderLinkDismiss() -> Bool
}
