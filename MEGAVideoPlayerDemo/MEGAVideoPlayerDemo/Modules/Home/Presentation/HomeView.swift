import CasePaths
import MEGASdk
import MEGAUIComponent
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            VStack(spacing: .zero) {
                List {
                    if let nodes = viewModel.nodes {
                        ForEach(nodes) { node in
                            Button(node.name ?? "Unnamed Node") {
                                viewModel.didTapNode(node)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
                MEGABottomAnchoredButtons(
                    buttons: [
                        MEGAButton("Logout") {
                            Task { await viewModel.didTapLogout() }
                        }
                    ]
                )
            }
            .navigationTitle("Videos (\(viewModel.selectedPlayerOption.rawValue))")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: MEGANode.self) { node in
                MEGAPlayerView(node: node)
                    .navigationTitle(viewModel.selectedPlayerOption.rawValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(VideoPlayerOption.allCases) { option in
                            Button {
                                viewModel.selectedPlayerOption = option
                            } label: {
                                Label(option.rawValue, systemImage: viewModel.selectedPlayerOption == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Text("Select Player")
                    }
                }
            }
        }
        .task { await viewModel.viewWillAppear() }
    }
}

extension MEGAPlayerView {
    init(node: MEGANode) {
        self.init(viewModel: VideoPlayerFactory.liveValue.playerViewModel(for: node))
    }
}

#Preview {
    HomeView(viewModel: .liveValue)
}
