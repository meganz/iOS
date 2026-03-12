import MEGADomain
import SwiftUI

struct RecentActionBucketContainerView: View {
    typealias NodeActionHandler = @MainActor (NodeEntity) -> Void
    typealias BucketSelectionHandler = @MainActor (RecentActionBucketEntity) -> Void
    
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let userNameProvider: any UserNameProviderProtocol
        let nodeActionHandler: NodeActionHandler
        let bucketSelectionHandler: BucketSelectionHandler
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
            RecentActionBucketView(dependency: contentDependency) {
                dependency.nodeActionHandler(fileNode)
            }
        case let .singleMedia(mediaNode):
            RecentActionBucketView(dependency: contentDependency) {
                dependency.nodeActionHandler(mediaNode)
            }
        case .mixedFiles, .multipleMedia:
            RecentActionBucketView(dependency: contentDependency, moreAction: nil)
        }
    }
}
