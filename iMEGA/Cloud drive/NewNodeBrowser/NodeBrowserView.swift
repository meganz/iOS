import MEGADomain
import Search
import SwiftUI

struct NodeBrowserView: View {
    @StateObject var viewModel: NodeBrowserViewModel
    var body: some View {
        VStack {
            if viewModel.isMediaDiscoveryShown, let mediaDiscoveryViewModel = viewModel.mediaDiscoveryViewModel {
                MediaDiscoveryContentView(viewModel: mediaDiscoveryViewModel)
            } else {
                SearchResultsView(viewModel: viewModel.searchResultsViewModel)
            }
        }
        .task { await viewModel.viewTask() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker(selection: $viewModel.viewMode, label: Text("ViewMode")) {
                        Text("Media Discovery").tag(ViewModePreferenceEntity.mediaDiscovery)
                        Text("List").tag(ViewModePreferenceEntity.list)
                        Text("Thumbnails").tag(ViewModePreferenceEntity.thumbnail)
                    }
                }
            label: {
                Label("Sort", systemImage: "ellipsis")
            }
            }
        }
    }
}
