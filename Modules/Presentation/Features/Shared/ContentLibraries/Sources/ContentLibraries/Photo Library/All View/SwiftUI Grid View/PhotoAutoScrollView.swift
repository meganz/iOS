import Combine
import SwiftUI

struct PhotoAutoScrollView: View {
    @StateObject var viewModel: PhotoAutoScrollViewModel
    let scrollProxy: ScrollViewProxy
    
    var body: some View {
        EmptyView()
            .onChange(of: viewModel.autoScrollWithAnimation) { _ in
                withAnimation(.default.speed(3)) {
                    scrollProxy.scrollTo(viewModel.position, anchor: .center)
                }
            }
            .onChange(of: viewModel.autoScrollWithoutAnimation) { _ in
                scrollProxy.scrollTo(viewModel.position, anchor: .center)
            }
    }
}
