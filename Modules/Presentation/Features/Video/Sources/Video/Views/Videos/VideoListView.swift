import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel: VideoListViewModel
    
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoListViewModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        VStack(spacing: 0) {
            chipsView()
                .frame(height: viewModel.shouldShowFilterChip ? 60 : 0)
                .opacity(viewModel.shouldShowFilterChip ? 1 : 0)
                .animation(.easeInOut(duration: 0.05), value: viewModel.shouldShowFilterChip)
            content
                .overlay(placeholder)
        }
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
        switch viewModel.viewState {
        case .loading, .loaded, .partial:
            listView()
        case .empty, .error:
            videoEmptyView()
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        if #available(iOS 16.4, *) {
            iOS16SupportBottomSheetView()
                .presentationCornerRadius(16)
        } else if #available(iOS 16, *) {
            iOS16SupportBottomSheetView()
        } else {
            bottomSheetView()
        }
    }
    
    @available(iOS 16.0, *)
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
                ? $viewModel.selectedLocationFilterOption
                : $viewModel.selectedDurationFilterOption
            )
        } else {
            EmptyView()
        }
    }
    
    private func videoEmptyView() -> some View {
        VideoListEmptyView(
            videoConfig: .preview,
            image: VideoConfig.preview.videoListAssets.noResultVideoImage,
            text: Strings.Localizable.Videos.Tab.All.Content.emptyState
        )
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            videos: viewModel.videos,
            videoConfig: videoConfig,
            selection: viewModel.selection,
            router: router,
            viewType: .allVideos,
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
