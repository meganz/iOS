import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
struct RecentActionBucketModelMapper {
    private let userNameProvider: any UserNameProviderProtocol
    
    init(userNameProvider: some UserNameProviderProtocol) {
        self.userNameProvider = userNameProvider
    }
    
    func map(from bucket: RecentActionBucketEntity) -> RecentActionBucketModel {
        RecentActionBucketModel(
            thumbnail: thumbnail(bucketType: bucket.type),
            title: title(bucketType: bucket.type),
            parentFolderName: bucket.parent?.name ?? "",
            changedBy: changedBy(changesType: bucket.changesType, changesOwnerType: bucket.changesOwnerType),
            isShared: isShared(shareOriginType: bucket.shareOriginType),
            isUpdate: bucket.changesType == .updatedFiles
        )
    }
    
    private func changedBy(changesType: RecentActionBucketChangesType, changesOwnerType: RecentActionBucketChangesOwnerType) -> String? {
        switch changesOwnerType {
        case .currentUser:
            return nil
        case let .otherUser(user):
            guard let username = userNameProvider.displayName(for: user) else { return nil }
            return switch changesType {
            case .newFiles:
                Strings.Localizable.Home.Recent.addedByLabel(username)
            case .updatedFiles:
                Strings.Localizable.Home.Recent.modifiedByLabel(username)
            }
        }
    }
    
    private func thumbnail(bucketType: RecentActionBucketType) -> Image {
        switch bucketType {
        case .singleFile(let node):
            MEGAAssets.Image.image(forFileExtension: node.name.pathExtension)
        case .singleMedia(let node):
            MEGAAssets.Image.image(forFileExtension: node.name.pathExtension)
        case .multipleMedia:
            MEGAAssets.Image.filetypeImagesStack
        case .mixedFiles:
            MEGAAssets.Image.filetypeGenericStack
        }
    }
    
    private func title(bucketType: RecentActionBucketType) -> String {
        switch bucketType {
        case let .singleFile(node), let .singleMedia(node):
            if node.isNodeKeyDecrypted {
                return node.name
            } else {
                return Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(1)
            }
        case let .multipleMedia(nodes), let .mixedFiles(nodes):
            if let firstNode = nodes.first, firstNode.isNodeKeyDecrypted {
                return Strings.Localizable.Recents.Section.MultipleFile.title(nodes.count - 1).replacingOccurrences(of: "[A]", with: firstNode.name)
            } else {
                return Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(nodes.count)
            }
        }
    }
    
    private func isShared(shareOriginType: RecentActionBucketShareOriginType) -> Bool {
        switch shareOriginType {
        case .none:
            false
        case .inShare, .outShare:
            true
        }
    }
}
