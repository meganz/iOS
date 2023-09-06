import MEGASwiftUI
import SwiftUI

public struct SearchResultsView: View {
    public init(viewModel: @autoclosure @escaping () -> SearchResultsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    @StateObject var viewModel: SearchResultsViewModel

    public var body: some View {
        
        ScrollView {
            LazyVStack {
                ForEach(viewModel.listItems) { item in
                    SearchResultRowView(viewModel: item)
                }
            }
            .overlay(
                emptyView
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .padding(.bottom, viewModel.bottomInset)
        .taskForiOS14 {
            viewModel.task()
        }
    }
    
    @ViewBuilder
    var emptyView: some View {
        // empty state handling will be added
        // in the FM-800
        EmptyView()
    }
}

@available(iOS 15.0, *)
struct SearchResultsViewPreviews: PreviewProvider {
    
    struct Wrapper: View {
        @State var text: String = ""
        @StateObject var viewModel = SearchResultsViewModel(
            resultsProvider: NonProductionTestResultsProvider(),
            bridge: .init(selection: { _ in }, context: {_, _ in })
        )
        var body: some View {
            SearchResultsView(
                viewModel: viewModel
            )
            .onChange(of: text, perform: { newValue in
                viewModel.bridge.queryChanged(newValue)
            })
            .searchable(text: $text)
        }
    }
    static var previews: some View {
        NavigationView {
            Wrapper()
        }
    }
}
