import MEGASwiftUI
import SwiftUI

public struct SearchResultsView: View {
    public init(viewModel: @autoclosure @escaping () -> SearchResultsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    @StateObject var viewModel: SearchResultsViewModel

    public var body: some View {
        VStack(spacing: .zero) {
            chipsView
            content
        }
    }
    
    private var chipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.chipsItems) { chip in
                    PillView(viewModel: chip.pill)
                        .onTapGesture {
                            Task {
                                await chip.select()
                            }
                        }
                }
                Spacer()
            }
        }
        .padding([.leading, .trailing, .top, .bottom])
    }
    
    private var emptyView: some View {
        // placeholder for [FM-800]
        EmptyView()
    }
    
    private var content: some View {
        List {
            ForEach(Array(viewModel.listItems.enumerated()), id: \.element.id) { index, item in
                SearchResultRowView(viewModel: item)
                    .listRowInsets(
                        EdgeInsets(
                            top: index != 0 ? 8 : 0,
                            leading: 0,
                            bottom: 0,
                            trailing: 0
                        )
                    )
            }
        }
        .listStyle(.plain)
        .overlay(
            emptyView
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.bottom, viewModel.bottomInset)
        .taskForiOS14 {
            await viewModel.task()
        }
    }
}

@available(iOS 15.0, *)
struct SearchResultsViewPreviews: PreviewProvider {
    
    struct Wrapper: View {
        @State var text: String = ""
        @StateObject var viewModel = SearchResultsViewModel(
            resultsProvider: NonProductionTestResultsProvider(),
            bridge: .init(selection: { _ in }, context: {_, _ in }),
            config: .init(
                chipAssets: .init(
                    selectedForeground: .white,
                    selectedBackground: .green,
                    normalForeground: .black,
                    normalBackground: .gray
                )
            )
            
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
