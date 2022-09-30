import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionDetailView: View {
    @ObservedObject var viewModel: SlideShowOptionCellViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
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
            Spacer().layoutPriority(1)
        }
        .listStyle(.plain)
        .navigationViewStyle(.stack)
    }
    
    var navBarButton: some View {
        Button {
            isShowing.toggle()
        } label: {
            Image(uiImage: UIImage(asset: Asset.Images.Chat.backArrow))
                .frame(width: 18, height: 24)
                .foregroundColor(.primary.opacity(0.8))
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Text(viewModel.title)
                .font(.headline)
                .padding(.vertical, 26)
        }
        .overlay(
            HStack {
                navBarButton
                Spacer()
            }.padding()
        )
    }
}
