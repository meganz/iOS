import SwiftUI

/// Note: Example to use RecentActionBucketView only. To be refined in this ticket IOS-11383
struct RecentWidgetBucketListView: View {
    struct Dependency {
        let buckets: [RecentActionBucketEntity]
        let userNameProvider: any UserNameProviderProtocol
    }
    
    private let dependency: Dependency
    
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(dependency.buckets) { bucket in
                RecentActionBucketContainerView(
                    dependency: RecentActionBucketContainerView.Dependency(
                        bucket: bucket,
                        userNameProvider: dependency.userNameProvider,
                        nodeActionHandler: { node in
                            print(node.name)
                        },
                        bucketSelectionHandler: { bucket in
                            print(bucket.type)
                        }
                    )
                )
            }
        }
    }
}
