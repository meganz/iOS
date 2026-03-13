import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentActionBucketSection: Identifiable {
    var id: String { title }
    let title: String
    let buckets: [RecentActionBucketEntity]
}

struct RecentWidgetBucketListView: View {
    struct Dependency {
        let bucketGroups: [DailyRecentActionBucketGroup]
        let userNameProvider: any UserNameProviderProtocol
    }
    
    enum Route {
        case viewAllBuckets
    }
    
    private let dependency: Dependency
    private let sections: [RecentActionBucketSection]
    private let recentActionBucketSectionMapper = RecentActionBucketSectionMapper()
    
    @EnvironmentObject var navigator: HomeNavigation
    
    init(dependency: Dependency) {
        self.dependency = dependency
        self.sections = recentActionBucketSectionMapper.map(
            bucketGroups: dependency.bucketGroups
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            bucketsContent
            viewAllBucketsButton
        }
        .navigationDestination(for: Route.self) { route in
            navigationDestination(for: route)
        }
    }
    
    private var bucketsContent: some View {
        ForEach(sections) { section in
            Section {
                ForEach(section.buckets) { bucket in
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
            } header: {
                Text(section.title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .padding(.horizontal, TokenSpacing._5)
                    .padding(.vertical, TokenSpacing._3)
            }
        }
    }
    
    private var viewAllBucketsButton: some View {
        Button {
            navigator.append(Route.viewAllBuckets)
        } label: {
            Text(Strings.Localizable.Home.Recent.Widget.viewAll)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Button.primary.swiftUI)
        }
        .padding(TokenSpacing._5)
    }
    
    @ViewBuilder
    private func navigationDestination(for route: Route) -> some View {
        switch route {
        case .viewAllBuckets:
            RecentAllBucketsView(
                dependency: RecentAllBucketsView.Dependency(
                    userNameProvider: dependency.userNameProvider
                )
            )
        }
    }
}
