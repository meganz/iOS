import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            .navigationBarItems(leading: navBarButton, trailing: EmptyView())
        }
        .navigationViewStyle(.stack)
    }
    
    var navBarButton: some View {
        Button {
            isShowing.toggle()
        } label: {
            Image(uiImage: UIImage(asset: Asset.Images.Chat.backArrow))
                .frame(width: 18, height: 24)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(Colors.General.Black._161616.color))
                .contentShape(Rectangle())
        }
    }
}
