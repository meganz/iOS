import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct HomeView: View {
    public struct Dependency {
        let homeAddMenuActionHandler: any HomeAddMenuActionHandling
        public init(
            homeAddMenuActionHandler: some HomeAddMenuActionHandling
        ) {
            self.homeAddMenuActionHandler = homeAddMenuActionHandler
        }
    }

    @StateObject var viewModel = HomeViewModel()

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public var body: some View {
        listContent
            .navigationTitle(Strings.Localizable.home)
            .embedInScrollViewWithDirectionChangeHandler {
                viewModel.hidesFloatingActionsButton = $0
            }
            .floatingButton(isHidden: viewModel.hidesFloatingActionsButton) {
                viewModel.presentsSheet.toggle()
            }
            .sheet(isPresented: $viewModel.presentsSheet) {
                HomeMenuActionsSheetView(isPresented: $viewModel.presentsSheet, selection: $viewModel.selectedFloatingButtonAction)
            }
            .onReceive(viewModel.$selectedFloatingButtonAction.compactMap { $0 }) {
                dependency.homeAddMenuActionHandler.handleAction($0)
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
