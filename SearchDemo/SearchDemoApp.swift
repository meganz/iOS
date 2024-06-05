import MEGAUIKit
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
                .toolbar {
                    EditButton()
                }
        }
    }
    struct Wrapper: View {
        @State var text: String = ""
        @Environment(\.editMode) private var editMode
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
                }, sortingOrder: {
                    .nameAscending
                }
            ),
            config: .testConfig,
            layout: .list,  
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default), 
            viewDisplayMode: .unknown
        )
        var body: some View {
            SearchResultsView(viewModel: viewModel)
            .toolbar {
                Button(
                    action: {
                        viewModel.layout.toggle()
                    },
                    label: {
                        viewModel.layout == .list ?
                        Text("Thumbnails") :
                        Text("List")
                    }
                )
            }
            .onChange(of: text, initial: true, { _, newValue in
                viewModel.bridge.queryChanged(newValue)
            })
            .searchable(text: $text)
        }
    }
}

#Preview {
    ContentView()
}
