import MEGASwiftUI
import SwiftUI

public struct SearchResultsContainerView: View {
    enum Constants {
        static let floatingAddButtonBottomInset = 70.0
    }
    @StateObject var viewModel: SearchResultsContainerViewModel

    public init(viewModel: @autoclosure @escaping () -> SearchResultsContainerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: .zero) {
            header
                .transition(.opacity)
            SearchResultsView(viewModel: viewModel.searchResultsViewModel)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Spacer()
                        .frame(height: viewModel.searchResultsViewModel.usesRevampedLayout ? Constants.floatingAddButtonBottomInset : 0)
                }
        }
        .task {
            await viewModel.task()
        }
        .sheet(item: $viewModel.presentedChipsPickerViewModel) { item in
            chipsPickerView(for: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showSortSheet) {
            SearchResultsSortOptionsView(viewModel: viewModel.displaySortOptionsViewModel)
        }
    }

    @ViewBuilder
    private var header: some View {
        if viewModel.showChips {
            chips
        } else if viewModel.showSorting, let sortHeaderViewModel = viewModel.sortHeaderViewModel {
            SearchResultsHeaderView {
                SearchResultsHeaderSortView(viewModel: sortHeaderViewModel)
            } rightView: {
                SearchResultsHeaderViewModeView(viewModel: viewModel.viewModeHeaderViewModel)
            }
        }
    }

    @ViewBuilder
    private var chips: some View {
        HStack {
            ForEach(viewModel.chipsItems) { chip in
                PillView(viewModel: chip.pill)
                    .onTapGesture {
                        Task { @MainActor in
                            await chip.select()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing, .bottom])
        .padding(.top, 6)
    }

    private func chipsPickerView(for item: ChipViewModel) -> some View {
        ChipsPickerView(
            viewModel: .init(
                title: item.subchipsPickerTitle ?? "",
                chips: item.subchips,
                closeIcon: viewModel.chipAssets.closeIcon,
                colorAssets: viewModel.colorAssets,
                chipSelection: { chip in
                    Task { @MainActor in
                        await chip.select()
                    }
                },
                dismiss: {
                    Task { @MainActor in
                        await viewModel.dismissChipGroupPicker()
                    }
                }
            )
        )
    }
}
