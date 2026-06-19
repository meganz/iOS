import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import UIKit

struct RecentActionBucketModel {
    let thumbnail: Image
    let title: String
    let parentFolderName: String
    let changedBy: String?
    let isShared: Bool
    let isUpdate: Bool
}

struct RecentActionBucketView: View {
    private enum Constants {
        static let moreActionButtonSize: CGFloat = 40
    }

    struct Dependency {
        let bucket: RecentActionBucketEntity
        let userNameProvider: any UserNameProviderProtocol
    }

    typealias MoreActionHandler = @MainActor (UIButton) -> Void
    typealias SelectionHandler = @MainActor () -> Void
    private let bucketModel: RecentActionBucketModel
    private let moreActionHandler: MoreActionHandler?
    private let selectionHandler: SelectionHandler

    init(dependency: Dependency, moreAction: MoreActionHandler?, onSelect: @escaping SelectionHandler) {
        let mapper = RecentActionBucketModelMapper(userNameProvider: dependency.userNameProvider)
        self.bucketModel = mapper.map(from: dependency.bucket)
        self.moreActionHandler = moreAction
        self.selectionHandler = onSelect
    }

    private var hasMoreAction: Bool {
        moreActionHandler != nil
    }

    var body: some View {
        content
    }

    // The moreActionView is overlaid on top of the row content rather than placed beside it in the same HStack, so its
    // tap gesture isn't intercepted by the row's selection tap gesture.
    private var content: some View {
        rowContent
            .padding(.leading, TokenSpacing._4)
            .padding(.vertical, TokenSpacing._3)
            .padding(.trailing, hasMoreAction ? TokenSpacing._5 + Constants.moreActionButtonSize + TokenSpacing._4 : TokenSpacing._5)
            .contentShape(Rectangle())
            .onTapGesture {
                selectionHandler()
            }
            .overlay(alignment: .trailing) {
                moreActionView
                    .padding(.trailing, TokenSpacing._5)
            }
    }

    private var rowContent: some View {
        HStack(spacing: TokenSpacing._4) {
            thumbnailView

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                titleView
                changesOriginView
                HStack(spacing: TokenSpacing._2) {
                    updateIcon
                    sharedFolderIcon
                    parentFolderNameView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var titleView: some View {
        Text(bucketModel.title)
            .font(.subheadline)
            .fontWeight(.regular)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }
    
    @ViewBuilder
    private var changesOriginView: some View {
        if let changesOrigin = bucketModel.changedBy {
            Text(changesOrigin)
                .font(.footnote)
                .fontWeight(.regular)
                .lineLimit(1)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }
    
    private var parentFolderNameView: some View {
        Text(bucketModel.parentFolderName)
            .font(.caption)
            .fontWeight(.regular)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }
    
    private var thumbnailView: some View {
        bucketModel.thumbnail
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)
    }
    
    @ViewBuilder
    private var sharedFolderIcon: some View {
        if bucketModel.isShared {
            MEGAAssets.Image.folderUsers
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 16, height: 16)
        }
    }
    
    @ViewBuilder
    private var updateIcon: some View {
        if bucketModel.isUpdate {
            MEGAAssets.Image.clockRotate
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle( TokenColors.Icon.secondary.swiftUI)
                .frame(width: 16, height: 16)
        }
    }
    
    @ViewBuilder
    private var moreActionView: some View {
        if let moreActionHandler {
            ImageButtonWrapper(
                image: MEGAAssets.Image.moreHorizontal,
                imageColor: TokenColors.Icon.secondary.swiftUI
            ) { button in
                moreActionHandler(button)
            }
            .frame(width: Constants.moreActionButtonSize, height: Constants.moreActionButtonSize)
        }
    }
}
