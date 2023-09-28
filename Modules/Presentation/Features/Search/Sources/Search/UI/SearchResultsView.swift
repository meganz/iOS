import MEGASwift
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
            if viewModel.isLoadingPlaceholderShown {
                placeholderContent
            } else {
                content
            }
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
        .padding([.leading, .trailing, .bottom])
        .padding(.top, 6)
    }

    private var content: some View {
        List {
            ForEach(viewModel.listItems) {
                SearchResultRowView(viewModel: $0)
            }
        }
        .simultaneousGesture(
            DragGesture().onChanged({ _ in
                viewModel.scrolled()
            })
        )
        .listStyle(.plain)
        .padding(.bottom, viewModel.bottomInset)
        .emptyState(viewModel.emptyViewModel)
        .taskForiOS14 {
            await viewModel.task()
        }
    }

    private var placeholderContent: some View {
        ScrollView {
            VStack(spacing: .zero) {
                ForEach(0..<9, id: \.self) { _ in
                    placeholderRowView
                }
            }
        }
    }

    private var placeholderRowView: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 100)
                    .frame(width: 152, height: 20)

                RoundedRectangle(cornerRadius: 100)
                    .frame(width: 121, height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 0)
                .frame(width: 28, height: 28)
        }
        .padding()
        .shimmering()
    }
}

@available(iOS 15.0, *)
struct SearchResultsViewPreviews: PreviewProvider {
    
    struct Wrapper: View {
        @State var text: String = ""
        @StateObject var viewModel = SearchResultsViewModel(
            resultsProvider: NonProductionTestResultsProvider(),
            bridge: .init(
                selection: { _ in },
                context: {_, _ in },
                resignKeyboard: {},
                chipTapped: { _, _ in }
            ),
            config: .init(
                chipAssets: .init(
                    selectedForeground: .white,
                    selectedBackground: .green,
                    normalForeground: .black,
                    normalBackground: .gray
                ),
                emptyViewAssetFactory: { _ in
                        .init(
                            image: Image(systemName: "magnifyingglass.circle.fill"),
                            title: "No results",
                            foregroundColor: Color(red: 209.0/255.0, green: 209.0/255.0, blue: 209.0/255.0)
                        )
                },
                rowAssets: .init(
                    contextImage: .init(systemName: "ellipsis")!
                )
            ),
            keyboardVisibilityHandler: MockKeyboardVisibilityHandler()

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
