import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct HomeView: View {
    private let menuActionsSheetViewModel: HomeMenuActionsSheetViewModel
    @StateObject private var floatingButtonVisibilityViewModel: HomeFloatingButtonVisibilityViewModel
    @StateObject var viewModel: HomeViewModel

    public init(menuActionsSheetViewModel: HomeMenuActionsSheetViewModel) {
        self.menuActionsSheetViewModel = menuActionsSheetViewModel
        _floatingButtonVisibilityViewModel = StateObject(wrappedValue: HomeFloatingButtonVisibilityViewModel())
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    public var body: some View {
        listContent
            .navigationTitle(Strings.Localizable.home)
            .embedInScrollViewWithDirectionChangeHandler {
                floatingButtonVisibilityViewModel.hidesFloatingActionsButton = $0
            }
            .floatingButton(isHidden: floatingButtonVisibilityViewModel.hidesFloatingActionsButton) {
                viewModel.presentsSheet.toggle()
            }
            .sheet(isPresented: $viewModel.presentsSheet) {
                HomeMenuActionsSheetView(viewModel: menuActionsSheetViewModel, isPresented: $viewModel.presentsSheet)
            }
    }

    private var listContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.widgets) { widget in
                switch widget {
                case .shortcuts:
                    ShortcutsWidgetView()
                }
            }
            ForEach(0..<10, id: \.self) { index in
                RowView()
                    .background((index % 2 == 0 ? Color.red : Color.yellow))

            }
        }
    }

    // Debug only, will remove later
    private struct RowView: View {
        @State var height = 60.0
        @State var expanded = false
        var body: some View {
            Button {

                withAnimation {
                    if expanded { height /= 2 } else { height *= 2 }
                    expanded.toggle()
                }
            } label: {
                Text("Click to \(expanded ? "collapse" : "expand")")
            }
            .frame(height: height)
                .frame(maxWidth: .infinity)
        }
    }
}
