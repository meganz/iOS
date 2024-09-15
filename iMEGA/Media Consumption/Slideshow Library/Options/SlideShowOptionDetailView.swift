import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SlideShowOptionDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionCellViewModel
    @Binding var isShowing: Bool
    
    private var navBarButtonTintColor: Color {
        TokenColors.Text.primary.swiftUI
    }
    
    var body: some View {
        ZStack {
            TokenColors.Background.surface1.swiftUI
            
            VStack(spacing: 0) {
                navigationBar
                    .background(TokenColors.Background.surface1.swiftUI)
                listView()
            }
        }
    }
    
    var navBarButton: some View {
        Button {
            isShowing.toggle()
        } label: {
            Text(Strings.Localizable.cancel)
                .font(.body)
                .foregroundColor(navBarButtonTintColor)
                .padding()
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        Text(viewModel.title)
            .font(.body.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .frame(maxWidth: .infinity, minHeight: 60.0)
            .overlay(
                HStack {
                    Spacer()
                    navBarButton
                }
            )
    }
    
    @ViewBuilder func listView() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Divider()
                ForEach(viewModel.children, id: \.self.id) { item in
                    SlideShowOptionDetailCellView(viewModel: item)
                        .onTapGesture {
                            viewModel.didSelectChild(item)
                            withAnimation(.easeOut(duration: 1)) {
                                isShowing.toggle()
                            }
                        }
                    Divider().padding(.leading, item.id == viewModel.children.last?.id ? 0 : 16)
                }
                Divider()
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }
}
