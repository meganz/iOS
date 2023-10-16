import MEGASwift
import Search
import SearchMock
import SwiftUI

@main
struct SearchDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            Wrapper()
        }
    }
    struct Wrapper: View {
        @State var text: String = ""
        @StateObject var viewModel = SearchResultsViewModel(
            resultsProvider: NonProductionTestResultsProvider(),
            bridge: .init(
                selection: {
                    print("Item selected \($0)")
                },
                context: { result, _ in
                    print("Context menu \(result)")
                },
                resignKeyboard: {
                    print("Resign keyboard")
                },
                chipTapped: {
                    print("Chip tapped \($0), \($1)")
                }
            ),
            config: .testConfig,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default)
        )
        var body: some View {
            SearchResultsView(
                viewModel: viewModel
            )
            .onChange(of: text, initial: true, { _, newValue in
                viewModel.bridge.queryChanged(newValue)
            })
            .searchable(text: $text)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
