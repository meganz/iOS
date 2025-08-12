import CasePaths
import MEGASdk
import MEGAUIComponent
import MEGAVideoPlayer
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
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
            .fullScreenCover(item: $viewModel.selectedVideoNode) { node in
                MEGAPlayerView(node: node)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(VideoPlayerOption.allCases) { option in
                            Button {
                                viewModel.didSelectPlayerOption(option)
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
        self.init(
            viewModel: VideoPlayerFactory.liveValue.playerViewModel(for: node)
        )
    }
}

#Preview {
    HomeView(viewModel: .liveValue)
}
