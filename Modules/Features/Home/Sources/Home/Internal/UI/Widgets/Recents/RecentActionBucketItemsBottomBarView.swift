import MEGAAssets
import MEGAL10n
import SwiftUI

typealias MoreActionsHandler = @MainActor () -> Void

struct RecentActionBucketItemsBottomBarView: View {
    @Binding var bottomBarAction: RecentActionBottomBarAction?
    let moreActionsHandler: MoreActionsHandler
    private let viewModel: RecentActionBucketItemsBottomBarViewModel

    init(
        bucket: RecentActionBucketEntity,
        bottomBarAction: Binding<RecentActionBottomBarAction?>,
        moreActionsHandler: @escaping MoreActionsHandler
    ) {
        self.viewModel = RecentActionBucketItemsBottomBarViewModel(bucket: bucket)
        self._bottomBarAction = bottomBarAction
        self.moreActionsHandler = moreActionsHandler
    }

    var body: some View {
        let configuration = viewModel.configuration
        ForEach(configuration.actions) { action in
            if let firstAction = configuration.actions.first, firstAction != action { Spacer() }
            
            Button {
                bottomBarAction = action
            } label: {
                Label(title: { Text(action.title) }, icon: { action.icon })
            }
            .labelStyle(.iconOnly)
        }
        
        if configuration.showsMoreButton {
            Spacer()
            Button {
                moreActionsHandler()
            } label: {
                Label(title: { Text(Strings.Localizable.more) }, icon: { MEGAAssets.Image.moreHorizontal })
            }
            .labelStyle(.iconOnly)
        }
    }
}
