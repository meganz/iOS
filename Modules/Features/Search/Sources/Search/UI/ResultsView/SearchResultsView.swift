import MEGADesignToken
import MEGASwiftUI
import MEGAUIKit
import SwiftUI

struct SearchResultsView<Header: View>: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @Environment(\.editMode) private var editMode
    private let header: () -> Header

    init(viewModel: @autoclosure @escaping () -> SearchResultsViewModel, @ViewBuilder header: @escaping () -> Header) {
        _viewModel = ObservedObject(wrappedValue: viewModel())
        self.header = header
    }
    
    public var body: some View {
        PlaceholderContainerView(
            isLoading: $viewModel.isLoadingPlaceholderShown,
            content: content,
            placeholder: PlaceholderContentView(
                placeholderRow: placeholderRowView
            )
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            contentWrapper
                .scrollDismissesKeyboard(.immediately)
        }
        .padding(.bottom, viewModel.bottomInset)
        .emptyState(viewModel.emptyViewModel)
    }
    
    @ViewBuilder
    private var contentWrapper: some View {
        if viewModel.layout == .list {
            SearchResultsListView(viewModel: viewModel, header: header)
        } else {
            SearchResultsThumbnailView(viewModel: viewModel, header: header)
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
