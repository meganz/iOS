import MEGAAppPresentation
import MEGADomain
import SwiftUI

struct RecentActionBucketContainerView: View {
    typealias BucketSelectionHandler = @MainActor (RecentActionBucketEntity) -> Void
    typealias BucketCarouselPresenter = @MainActor (RecentActionBucketEntity) -> Void
    
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let userNameProvider: any UserNameProviderProtocol
        let nodeActionHandler: any NodesActionHandling
        let bucketSelectionHandler: BucketSelectionHandler
        let bucketCarouselPresenter: BucketCarouselPresenter?
    }
    
    private let dependency: Dependency
    
    private var contentDependency: RecentActionBucketView.Dependency {
        RecentActionBucketView.Dependency(
            bucket: dependency.bucket,
            userNameProvider: dependency.userNameProvider
        )
    }

    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                dependency.bucketSelectionHandler(dependency.bucket)
            }
    }
    
    private var content: RecentActionBucketView {
        switch dependency.bucket.type {
        case let .singleFile(fileNode):
            RecentActionBucketView(dependency: contentDependency) { button in
                dependency.nodeActionHandler.handle(action: NodeAction(handle: fileNode.handle, sender: button))
            }
        case let .singleMedia(mediaNode):
            RecentActionBucketView(dependency: contentDependency) { button in
                dependency.nodeActionHandler.handle(action: NodeAction(handle: mediaNode.handle, sender: button))
            }
        case .mixedFiles, .multipleMedia:
            RecentActionBucketView(dependency: contentDependency, moreAction: bucketCarouselMoreAction)
        }
    }

    private var bucketCarouselMoreAction: RecentActionBucketView.MoreActionHandler? {
        guard let presenter = dependency.bucketCarouselPresenter else { return nil }
        return { _ in presenter(dependency.bucket) }
    }
}
