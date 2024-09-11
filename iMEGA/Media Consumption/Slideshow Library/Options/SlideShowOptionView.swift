import MEGADesignToken
import SwiftUI

struct SlideShowOptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionViewModel
    let preference: any SlideShowViewModelPreferenceProtocol
    let router: any SlideShowOptionContentRouting
    var dismissal: () -> Void
    
    private var navBarButtonTintColor: Color {
        TokenColors.Text.primary.swiftUI
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            VStack(spacing: 0) {
                navigationBar
                    .background(TokenColors.Background.surface1.swiftUI)
                listView()
            }
        }
        .sheet(isPresented: $viewModel.shouldShowDetail) {
            detailView()
        }
        .onDisappear {
            preference.restart(withConfig: viewModel.configuration())
        }
    }
    
    var navBarButton: some View {
        Button {
            dismissal()
        } label: {
            Text(viewModel.doneButtonTitle)
                .font(.body.bold())
                .foregroundStyle(navBarButtonTintColor)
                .padding()
                .contentShape(Rectangle())
        }
    }
    
    var navigationBar: some View {
        Text(viewModel.navigationTitle)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .font(.body.bold())
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
            LazyVStack(alignment: .leading, spacing: 0) {
                Divider()
                ForEach(viewModel.cellViewModels, id: \.self.id) { cellViewModel in
                    router.slideShowOptionCell(for: cellViewModel)
                        .onTapGesture {
                            viewModel.didSelectCell(cellViewModel)
                        }
                    Divider().padding(.leading, cellViewModel.id == viewModel.cellViewModels.last?.id ? 0 : 16)
                }
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }
    
    @ViewBuilder func detailView() -> some View {
        if viewModel.shouldShowDetail {
            router.slideShowOptionDetailView(for: viewModel.selectedCell, isShowing: $viewModel.shouldShowDetail)
        }
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark: return MEGAAppColor.Black._1C1C1E.color
        default: return MEGAAppColor.White._F7F7F7.color
        }
    }
}
