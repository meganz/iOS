import SwiftUI

@MainActor
final class RecentAllBucketsViewModel: ObservableObject {
    @Published var buckets: [RecentActionBucketEntity] = []
}

/// Note: Example to use RecentActionBucketView only. To be refined in this ticket IOS-11385
struct RecentAllBucketsView: View {
    struct Dependency {
        let userNameProvider: any UserNameProviderProtocol
    }
    
    private let dependency: Dependency
    @StateObject private var viewModel = RecentAllBucketsViewModel()
    
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        List(viewModel.buckets) { bucket in
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
