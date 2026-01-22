import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct VideoListView: View {
    @StateObject private var viewModel: VideoListViewModel

    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting

    public init(
        viewModel: @autoclosure @escaping () -> VideoListViewModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }

    private var selectedLocationFilterOptionString: Binding<String> {
        Binding(
            get: { viewModel.selectedLocationFilterOption.stringValue },
            set: { newValue in
                if let filterOption = LocationChipFilterOptionType(rawValue: newValue) {
                    viewModel.selectedLocationFilterOption = filterOption
                }
            }
        )
    }

    private var selectedDurationFilterOptionString: Binding<String> {
        Binding(
            get: { viewModel.selectedDurationFilterOption.stringValue },
            set: { newValue in
                if let filterOption = DurationChipFilterOptionType(rawValue: newValue) {
                    viewModel.selectedDurationFilterOption = filterOption
                }
            }
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.mediaRevampEnabled {
                sortHeaderView()
                    .frame(height: viewModel.showSortHeader ? 36 : 0)
                    .clipped()
            } else {
                chipsView()
                    .frame(height: viewModel.showFilterChips ? 60 : 0)
                    .clipped()
                    .background(videoConfig.colorAssets.pageBackgroundColor)
            }
            content
                .overlay(placeholder)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showSortHeader)
        .animation(.easeInOut(duration: 0.25), value: viewModel.showFilterChips)
        .task { await viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .sheet(isPresented: $viewModel.isSheetPresented) {
            bottomView()
                .onDisappear {
                    guard let newlySelectedChip = viewModel.newlySelectedChip else {
                        return
                    }
                    viewModel.didFinishSelectFilterOption(newlySelectedChip)
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        listView()
            .emptyState(viewModel.emptyViewModel, usesRevampLayout: true)
            .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        if #available(iOS 16.4, *) {
            iOS16SupportBottomSheetView()
                .presentationCornerRadius(16)
        } else {
            iOS16SupportBottomSheetView()
        }
    }
    
    private func iOS16SupportBottomSheetView() -> some View {
        bottomSheetView()
            .presentationDetents([ .height(presentationDetentsHeight) ])
            .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func bottomSheetView() -> some View {
        if let newlySelectedChip = viewModel.newlySelectedChip {
            SingleSelectionBottomSheetView(
                videoConfig: videoConfig,
                title: viewModel.actionSheetTitle,
                options: viewModel.filterOptions,
                selectedOption: newlySelectedChip.type == .location
                ? selectedLocationFilterOptionString
                : selectedDurationFilterOptionString
            )
        } else {
            EmptyView()
        }
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            videos: viewModel.videos,
            searchText: viewModel.syncModel.searchText,
            videoConfig: videoConfig,
            selection: viewModel.selection,
            router: router,
            viewType: .allVideos,
            sectionTopInset: (viewModel.mediaRevampEnabled && viewModel.showSortHeader) ? 0 : TokenSpacing._5,
            thumbnailLoader: viewModel.thumbnailLoader,
            sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
            nodeUseCase: viewModel.nodeUseCase,
            featureFlagProvider: viewModel.featureFlagProvider
        )
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    private func chipsView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.chips, id: \.title) { item in
                    PillView(viewModel: PillViewModel(
                        title: item.title,
                        icon: .trailing(Image(uiImage: videoConfig.videoListAssets.chipDownArrowImage.withRenderingMode(.alwaysTemplate))),
                        foreground: item.isActive ? videoConfig.colorAssets.videoFilterChipActiveForegroundColor : videoConfig.colorAssets.videoFilterChipInactiveForegroundColor,
                        background: item.isActive ? videoConfig.colorAssets.videoFilterChipActiveBackgroundColor : videoConfig.colorAssets.videoFilterChipInactiveBackgroundColor
                    ))
                    .onTapGesture {
                        viewModel.newlySelectedChip = item
                        viewModel.isSheetPresented = true
                    }
                }
            }
            .padding([.leading, .trailing], 6)
            .padding([.top, .bottom], 12)
        }
    }

    @ViewBuilder
    private func sortHeaderView() -> some View {
        ResultsHeaderView(height: 44, leftView: {
            SortHeaderView(config: viewModel.sortHeaderConfig, selection: $viewModel.sortOrder)
        })
    }

    private var presentationDetentsHeight: CGFloat {
        let estimatedHeaderHeight: () -> CGFloat = {
            let titleHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight
            return titleHeight + 40
        }
        
        let estimatedContentHeight: () -> CGFloat = {
            let cellHeight: CGFloat = 50
            let itemCount = if viewModel.newlySelectedChip?.type == .location {
                LocationChipFilterOptionType.allCases.count
            } else {
                DurationChipFilterOptionType.allCases.count
            }
            let contentHeight = cellHeight * CGFloat(itemCount)
            return contentHeight + 100
        }
        return estimatedHeaderHeight() + estimatedContentHeight()
    }
    
    private var placeholder: some View {
        VideoListPlaceholderView(isActive: viewModel.viewState == .loading)
    }
}

#Preview {
    VideoListView(
        viewModel: VideoListViewModel(
            syncModel: VideoRevampSyncModel(),
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: Preview_PhotoLibraryUseCase()),
            selection: VideoSelection(),
            fileSearchUseCase: Preview_FilesSearchUseCase(),
            thumbnailLoader: Preview_ThumbnailLoader(),
            sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
            nodeUseCase: Preview_NodeUseCase(),
            featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false)
        ),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter()
    )
}
