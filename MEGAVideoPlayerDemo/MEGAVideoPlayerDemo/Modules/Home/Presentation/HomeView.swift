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
            .navigationTitle("Videos")
            .navigationDestination(for: MEGANode.self) { node in
                Text("\(node.name ?? "Unnamed")") // To be replaced with the revamped video player
            }
        }
        .task { await viewModel.viewWillAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

#Preview {
    HomeView(viewModel: .liveValue)
}
