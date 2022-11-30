import SwiftUI

struct SlideShowOptionDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionCellViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            Color(backGroundColor)
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
                .foregroundColor(Color(colorScheme == .dark ? UIColor.mnz_grayD1D1D1() : UIColor.mnz_gray515151()))
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
    
    private var backGroundColor: UIColor {
        switch colorScheme {
        case .dark: return UIColor.mnz_black1C1C1E()
        default: return UIColor.mnz_grayF7F7F7()
        }
    }
}
