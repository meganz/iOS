import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionViewModel
    let preference: SlideShowViewModelPreferenceProtocol
    let router: SlideShowOptionContentRouting
    var dismissal: () -> Void
    
    var body: some View {
        ZStack {
            Color(backGroundColor)
            VStack(spacing: 0) {
                navigationBar
                listView()
            }
        }
        .sheet(isPresented: $viewModel.shouldShowDetail) {
            detailView()
        }
    }
    
    var navBarButton: some View {
        Button {
            dismissal()
            preference.restart(withConfig: viewModel.configuration())
        } label: {
            Text(viewModel.doneButtonTitle)
                .font(.body.bold())
                .foregroundColor(Color(colorScheme == .dark ? UIColor.mnz_grayD1D1D1() : UIColor.mnz_gray515151()))
                .padding()
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        Text(viewModel.navigationTitle)
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
            LazyVStack(alignment: .leading, spacing: 0) {
                Divider()
                ForEach(viewModel.cellViewModels, id: \.self.id) { cellViewModel in
                    router.slideShowOptionCell(for: cellViewModel)
                        .onTapGesture {
                            viewModel.didSelectCell(cellViewModel)
                        }
                }
                Divider()
            }
        }
        .padding(.top, 36)
    }
    
    @ViewBuilder func detailView() -> some View {
        if viewModel.shouldShowDetail {
            router.slideShowOptionDetailView(for: viewModel.selectedCell, isShowing: $viewModel.shouldShowDetail)
        }
    }
    
    private var backGroundColor: UIColor {
        switch colorScheme {
        case .dark: return UIColor.mnz_black1C1C1E()
        default: return UIColor.mnz_grayF7F7F7()
        }
    }
}
