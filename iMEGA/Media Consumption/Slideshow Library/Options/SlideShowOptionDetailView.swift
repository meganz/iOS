import MEGAL10n
import SwiftUI

struct SlideShowOptionDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionCellViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            backgroundColor
            VStack(spacing: 0) {
                navigationBar
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
                .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color)
                .padding()
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        Text(viewModel.title)
            .font(.body.bold())
            .frame(maxWidth: .infinity)
            .overlay(
                HStack {
                    Spacer()
                    navBarButton
                }
            )
            .padding(.top, 28)
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
                }
                Divider()
            }
        }
        .padding(.top, 36)
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark: return MEGAAppColor.Black._1C1C1E.color
        default: return MEGAAppColor.White._F7F7F7.color
        }
    }
}
