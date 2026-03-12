import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct RecentActionBucketModel {
    let thumbnail: Image
    let title: String
    let parentFolderName: String
    let changedBy: String?
    let isShared: Bool
    let isUpdate: Bool
}

struct RecentActionBucketView: View {
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let userNameProvider: any UserNameProviderProtocol
    }
    
    typealias MoreActionHandler = @MainActor () -> Void
    private let bucketModel: RecentActionBucketModel
    private let moreActionHandler: MoreActionHandler?
    
    init(dependency: Dependency, moreAction: MoreActionHandler?) {
        let mapper = RecentActionBucketModelMapper(userNameProvider: dependency.userNameProvider)
        self.bucketModel = mapper.map(from: dependency.bucket)
        self.moreActionHandler = moreAction
    }
    
    var body: some View {
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

            moreActionView
        }
        .padding(.leading, TokenSpacing._4)
        .padding(.trailing, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
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
            Button {
                moreActionHandler()
            } label: {
                Label {
                    Text(Strings.Localizable.more)
                } icon: {
                    MEGAAssets.Image.moreList
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle( TokenColors.Icon.secondary.swiftUI)
                }
                .labelStyle(.iconOnly)
            }
            .frame(width: 40, height: 40)
        }
    }
}
