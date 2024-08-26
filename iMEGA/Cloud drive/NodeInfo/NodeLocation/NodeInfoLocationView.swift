import MEGASwiftUI
import SwiftUI

struct NodeInfoLocationView: View {
    
    @ObservedObject var viewModel: NodeInfoLocationViewModel
    
    var body: some View {
        LocationInfoMapTile(viewState: viewModel.viewState)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .task { await viewModel.onViewAppear() }
    }
}
