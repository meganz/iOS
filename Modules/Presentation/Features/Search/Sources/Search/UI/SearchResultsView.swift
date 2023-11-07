import MEGASwift
import MEGASwiftUI
import SwiftUI

public struct SearchResultsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @StateObject var viewModel: SearchResultsViewModel

    public init(viewModel: @autoclosure @escaping () -> SearchResultsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: .zero) {
            chipsView
            if viewModel.isThumbnailPreviewEnabled {
                changeModeButton
            }
            PlaceholderContainerView(
                isLoading: $viewModel.isLoadingPlaceholderShown,
                content: content,
                placeholder: PlaceholderContentView(placeholderRow: placeholderRowView)
            )
            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .taskForiOS14 {
            await viewModel.task()
        }
    }

    private var chipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.chipsItems) { chip in
                    PillView(viewModel: chip.pill)
                        .onTapGesture {
                            Task { @MainActor in
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

    @ViewBuilder
    private var content: some View {
        contentWrapper
            .simultaneousGesture(
                DragGesture().onChanged({ _ in
                    viewModel.scrolled()
                })
            )
            .padding(.bottom, viewModel.bottomInset)
            .emptyState(viewModel.emptyViewModel)
            .taskForiOS14 {
                await viewModel.task()
            }
    }

    @ViewBuilder
    private var contentWrapper: some View {
        if viewModel.displayMode == .list {
            listContent
        } else {
            thumbnailContent
        }
    }

    private var listContent: some View {
        List {
            ForEach(Array(viewModel.listItems.enumerated()), id: \.element.id) { index, item in
                SearchResultRowView(
                    viewModel: item,
                    selected: $viewModel.selected,
                    selectionMode: $viewModel.editing
                )
                .taskForiOS14 {
                    await viewModel.loadMoreIfNeeded(at: index)
                }
            }
        }
        .listStyle(.plain)
    }

    private var thumbnailContent: some View {
        ScrollView {
            LazyVGrid(
                columns: viewModel.columns(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                )
            ) {
                ForEach(Array(viewModel.folderListItems.enumerated()), id: \.element.id) { index, item in
                    SearchResultThumbnailItemView(viewModel: item)
                        .taskForiOS14 {
                            await viewModel.loadMoreIfNeededThumbnailMode(at: index, isFile: false)
                        }
                }
            }
            .padding(.horizontal, 8)

            LazyVGrid(
                columns: viewModel.columns(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                )
            ) {
                ForEach(Array(viewModel.fileListItems.enumerated()), id: \.element.id) { index, item in
                    SearchResultThumbnailItemView(viewModel: item)
                        .taskForiOS14 {
                            await viewModel.loadMoreIfNeededThumbnailMode(at: index, isFile: true)
                        }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var changeModeButton: some View {
        Button(action: {
            viewModel.changeMode()
        }, label: {
            // This is debug only, triggered by feature flag, so we don't need it localized
            Text("Toggle thumbnail view on/off")
        })
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
            resultsProvider: NonProductionTestResultsProvider(empty: true),
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
                    contextImage: UIImage(systemName: "ellipsis")!,
                    itemSelected: UIImage(systemName: "checkmark.circle")!,
                    itemUnselected: UIImage(systemName: "circle")!,
                    playImage: .init(systemName: "ellipsis")!,
                    downloadedImage: .init(systemName: "ellipsis")!,
                    moreList: UIImage(systemName: "ellipsis")!,
                    moreGrid: UIImage(systemName: "ellipsis")!
                ),
                colorAssets: .init(
                    F7F7F7: Color("F7F7F7"),
                    _161616: Color("161616"),
                    _545458: Color("545458"),
                    CE0A11: Color("CE0A11"),
                    F30C14: Color("F30C14"),
                    F95C61: Color("F95C61"),
                    F7363D: Color("F7363D"),
                    _1C1C1E: Color("1C1C1E")
                ),
                contextPreviewFactory: .init(
                    previewContentForResult: { result in
                        return .init(
                            actions: [],
                            previewMode: .preview({
                                UIHostingController(rootView: Text(result.title))
                            })
                        )
                    }
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
