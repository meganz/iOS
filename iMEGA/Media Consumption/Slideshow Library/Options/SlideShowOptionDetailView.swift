import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionDetailView: View {
    @ObservedObject var viewModel: SlideShowOptionCellViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                LazyVStack {
                    ForEach(viewModel.children, id: \.self.id) { item in
                        SlideShowOptionDetailCellView(viewModel: item)
                            .onTapGesture {
                                viewModel.didSelectChild(item)
                                withAnimation(.easeOut(duration: 1)) {
                                    isShowing.toggle()
                                }
                        }
                    }
                }
                .padding(.leading, 16)
                .padding(.top)
                Spacer()
            }
            .listStyle(.plain)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
