import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

public struct PDFViewerView: View {
    public struct Dependency {
        let actionContext: PDFViewerActionContext
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentURLUseCase: any PDFDocumentURLUseCaseProtocol
        let documentLoadingUseCase: any PDFViewerDocumentLoadingUseCaseProtocol
        let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol
        let leftOffItemRecordUseCase: any LeftOffItemRecordUseCaseProtocol
        /// The node recorded in Continue Where You Left Off; nil for a file
        /// that has no node.
        let node: NodeEntity?
        let nearestOutlineItemUseCase: any PDFNearestOutlineItemUseCaseProtocol
        let fileName: String
        let trackingUseCase: any PDFViewerTrackingUseCaseProtocol
        let onViewerPresented: @MainActor () -> Void
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let onClose: @MainActor () -> Void
        /// `nil` hides the ••• button.
        let moreMenuDependencies: PDFViewerTrailingPopoverDependencies?
        let downloadDependencies: PDFViewerTrailingPopoverDependencies?
        /// Invoked when the user taps a link inside the document.
        let onLinkTapped: @MainActor (URL) -> Void

        @MainActor
        public init(
            actionContext: PDFViewerActionContext = .init(),
            pdfDocumentSource: PDFViewerDocumentSource,
            downloadUseCase: some DownloadNodeUseCaseProtocol,
            lastPageUseCase: some PDFViewerLastPageUseCaseProtocol,
            leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol,
            node: NodeEntity?,
            fileName: String,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            onClose: @escaping @MainActor () -> Void,
            moreMenuDependencies: PDFViewerTrailingPopoverDependencies? = nil,
            downloadDependencies: PDFViewerTrailingPopoverDependencies? = nil,
            onLinkTapped: @escaping @MainActor (URL) -> Void = { _ in },
            trackingUseCase: some PDFViewerTrackingUseCaseProtocol = PDFViewerTrackingUseCase(),
            onViewerPresented: @escaping @MainActor () -> Void = {}
        ) {
            let documentLoader = PDFDocumentLoader()
            let outlineLoadingUseCase = PDFOutlineLoadingUseCase(
                documentLoader: documentLoader,
                outlineReader: PDFOutlineReader()
            )
            self.init(
                actionContext: actionContext,
                pdfDocumentSource: pdfDocumentSource,
                documentURLUseCase: PDFDocumentURLUseCase(downloadUseCase: downloadUseCase),
                documentLoadingUseCase: PDFViewerDocumentLoadingUseCase(
                    documentLoader: documentLoader,
                    outlineLoadingUseCase: outlineLoadingUseCase,
                    lastPageUseCase: lastPageUseCase
                ),
                lastPageUseCase: lastPageUseCase,
                leftOffItemRecordUseCase: leftOffItemRecordUseCase,
                node: node,
                nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
                fileName: fileName,
                transferIndicatorToolbarFactory: transferIndicatorToolbarFactory,
                onClose: onClose,
                moreMenuDependencies: moreMenuDependencies,
                downloadDependencies: downloadDependencies,
                onLinkTapped: onLinkTapped,
                trackingUseCase: trackingUseCase,
                onViewerPresented: onViewerPresented
            )
        }

        @MainActor
        init(
            actionContext: PDFViewerActionContext = .init(),
            pdfDocumentSource: PDFViewerDocumentSource,
            documentURLUseCase: some PDFDocumentURLUseCaseProtocol,
            documentLoadingUseCase: some PDFViewerDocumentLoadingUseCaseProtocol,
            lastPageUseCase: some PDFViewerLastPageUseCaseProtocol,
            leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol,
            node: NodeEntity?,
            nearestOutlineItemUseCase: some PDFNearestOutlineItemUseCaseProtocol,
            fileName: String,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            onClose: @escaping @MainActor () -> Void,
            moreMenuDependencies: PDFViewerTrailingPopoverDependencies? = nil,
            downloadDependencies: PDFViewerTrailingPopoverDependencies? = nil,
            onLinkTapped: @escaping @MainActor (URL) -> Void,
            trackingUseCase: some PDFViewerTrackingUseCaseProtocol = PDFViewerTrackingUseCase(),
            onViewerPresented: @escaping @MainActor () -> Void = {}
        ) {
            self.actionContext = actionContext
            self.pdfDocumentSource = pdfDocumentSource
            self.documentURLUseCase = documentURLUseCase
            self.documentLoadingUseCase = documentLoadingUseCase
            self.lastPageUseCase = lastPageUseCase
            self.leftOffItemRecordUseCase = leftOffItemRecordUseCase
            self.node = node
            self.nearestOutlineItemUseCase = nearestOutlineItemUseCase
            self.fileName = fileName
            self.trackingUseCase = trackingUseCase
            self.onViewerPresented = onViewerPresented
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
            self.onClose = onClose
            self.moreMenuDependencies = moreMenuDependencies
            self.downloadDependencies = downloadDependencies
            self.onLinkTapped = onLinkTapped
        }
    }

    @State private var viewModel: PDFViewerViewModel
    @State private var retryTask: Task<Void, Never>?
    @State private var attemptUnlockDocumentTask: Task<Void, Never>?

    private let onClose: @MainActor () -> Void

    private let onLinkTapped: @MainActor (URL) -> Void

    private let trailingToolbarContent: PDFViewerTrailingToolbarContent

    public init(dependency: Dependency) {
        onClose = dependency.onClose
        onLinkTapped = dependency.onLinkTapped
        let viewModel = PDFViewerViewModel(
            dependency: PDFViewerViewModel.Dependency(
                pdfDocumentSource: dependency.pdfDocumentSource,
                documentURLUseCase: dependency.documentURLUseCase,
                documentLoadingUseCase: dependency.documentLoadingUseCase,
                lastPageUseCase: dependency.lastPageUseCase,
                leftOffItemRecordUseCase: dependency.leftOffItemRecordUseCase,
                node: dependency.node,
                nearestOutlineItemUseCase: dependency.nearestOutlineItemUseCase,
                fileName: dependency.fileName,
                actionContext: dependency.actionContext,
                hasMoreAction: dependency.moreMenuDependencies != nil,
                hasDownloadAction: dependency.downloadDependencies != nil,
                trackingUseCase: dependency.trackingUseCase
            )
        )
        _viewModel = State(initialValue: viewModel)
        trailingToolbarContent = PDFViewerTrailingToolbarContent(
            action: viewModel.trailingAction,
            transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
            moreMenuDependencies: dependency.moreMenuDependencies,
            downloadDependencies: dependency.downloadDependencies
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                TokenColors.Background.page.swiftUI
                    .ignoresSafeArea()

                if let document = viewModel.pdfDocument {
                    PDFDisplayerView(
                        document: document,
                        currentPage: $viewModel.currentPageIndex,
                        isProgrammaticallyScrollingToCurrentPage:
                            $viewModel.isProgrammaticallyScrollingToCurrentPage,
                        searchRequest: $viewModel.searchRequest,
                        initialPageIndex: viewModel.initialPageIndex,
                        onLinkTapped: onLinkTapped,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isChromeHidden.toggle()
                            }
                        },
                        onIsScrolledToTopChange: { viewModel.isScrolledToTopDidChange($0) },
                        onInitialPageNavigationApplied: { viewModel.initialPageNavigationDidApply() },
                        onSearchSessionDidBegin: { viewModel.searchSessionDidBegin($0) },
                        onSearchSessionDidEnd: { viewModel.searchSessionDidEnd($0) },
                        onSearchResultDidChange: { viewModel.searchResultDidChange(sessionID: $0, generationID: $1, resultID: $2) }
                    )
                    .ignoresSafeArea()
                    // Makes Liquid Glass navbar/toolbar appearance update more
                    // likely when dismissing thumbnails view.
                    .opacity(viewModel.isShowingThumbnails ? 0 : 1)

                    if viewModel.isShowingThumbnails,
                       let thumbnailLoader = viewModel.thumbnailLoader {
                        PDFThumbnailGridView(
                            document: document,
                            currentPage: viewModel.currentPageIndex,
                            thumbnailLoader: thumbnailLoader,
                            onSelect: { pageIndex in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.didSelectThumbnail(at: pageIndex)
                                }
                            }
                        )
                        .transition(.opacity)
                    }
                }

                switch viewModel.state {
                case .loading(let progress):
                    loadingView(progress: progress)
                case .failed:
                    FileErrorView {
                        retryTask?.cancel()
                        retryTask = Task { await viewModel.retryDocumentLoad() }
                    }
                case .documentLocked:
                    loadingView(progress: nil, showsProgress: false)
                case .ready:
                    EmptyView()
                }
            }
            .ignoresSafeArea(.keyboard, edges: viewModel.isDocumentLocked ? .bottom : [])
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .toolbar(
                viewModel.isChromeHidden ? .hidden : .visible,
                for: .navigationBar
            )
            .toolbar(
                viewModel.state.isReady && !viewModel.isChromeHidden
                    ? .visible : .hidden,
                for: .bottomBar
            )
            .transparentLiquidGlassOrSolidOtherwiseToolbarBackground(for: .navigationBar)
            .transparentLiquidGlassOrSolidOtherwiseToolbarBackground(for: .bottomBar)
            .statusBarHidden(viewModel.isChromeHidden)
            .alert(
                Strings.Localizable.PdfPreview.Damaged.title,
                isPresented: $viewModel.isShowingDamagedFileAlert
            ) {
                Button(Strings.Localizable.ok) {}
            } message: {
                Text(Strings.Localizable.PdfPreview.Damaged.message)
            }
            .sheet(isPresented: $viewModel.isShowingOutline) {
                PDFOutlineSheet(
                    items: viewModel.outlineItems,
                    activeItemID: viewModel.activeOutlineItemID,
                    isLoading: viewModel.isLoadingOutline,
                    isShowingOutline: $viewModel.isShowingOutline,
                    onSelectOutlineItem: { item in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.didSelectOutlineItem(item)
                        }
                    }
                )
            }
        }
        .tint(TokenColors.Icon.primary.swiftUI)
        .accessibilityHidden(viewModel.isPasswordEntryPresented)
        .overlay {
            if viewModel.isPasswordEntryPresented {
                PDFViewerPasswordView(
                    password: $viewModel.password,
                    showInvalidPasswordError: viewModel.showInvalidPasswordError,
                    passwordRejectionCount: viewModel.passwordRejectionCount,
                    isSubmissionEnabled: viewModel.isSubmissionEnabled,
                    isSubmitting: attemptUnlockDocumentTask != nil,
                    onOpen: {
                        guard attemptUnlockDocumentTask == nil else { return }
                        attemptUnlockDocumentTask = Task {
                            await viewModel.submitPassword()
                            attemptUnlockDocumentTask = nil
                        }
                    },
                    onCancel: closeViewer
                )
            }
        }
        .task { await viewModel.loadDocumentFromSource() }
        .task(id: viewModel.outlineDocumentURL) {
            await viewModel.loadOutlineIfNeeded()
        }
        .onDisappear {
            retryTask?.cancel()
            retryTask = nil
            Task {
                await viewModel.saveLastReadPage()
                await viewModel.recordLeftOffItem()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                closeViewer()
            } label: {
                Image(uiImage: MEGAAssets.UIImage.backArrow) 
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .padding(10)
            }
            .accessibilityLabel(Strings.Localizable.close)
        }

        ToolbarItem(placement: .principal) {
            PDFViewerTitleView(
                fileName: viewModel.fileName,
                pageIndicatorText: viewModel.pageIndicatorText
            )
        }

        trailingToolbarContent

        if viewModel.state.isReady {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: TokenSpacing._7) {
                    if viewModel.showsOutlineButton {
                        Button {
                            viewModel.didOpenOutline()
                        } label: {
                            MEGAAssets.Image.listSmallMediumThinSolid
                        }
                        .accessibilityLabel(Strings.Localizable.PdfPreview.contents)
                    }

                    if viewModel.thumbnailLoader != nil {
                        PDFThumbnailsToggleView(
                            isActive: viewModel.isShowingThumbnails
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isShowingThumbnails.toggle()
                            }
                        }
                    }
                }
                .padding(.horizontal, TokenSpacing._2 + TokenSpacing._1)

                Spacer()

                Button {
                    viewModel.requestSearch()
                } label: {
                    Image(uiImage: MEGAAssets.UIImage.searchSmall)
                }
                .accessibilityLabel(Strings.Localizable.search)
            }
        }
    }

    private func closeViewer() {
        retryTask?.cancel()
        dismissPasswordEntry()
        onClose()
    }

    private func dismissPasswordEntry() {
        attemptUnlockDocumentTask?.cancel()
        attemptUnlockDocumentTask = nil
        viewModel.cancelPasswordEntry()
    }

    private func loadingView(progress: Float?, showsProgress: Bool = true) -> some View {
        VStack(spacing: TokenSpacing._6) {
            MEGAAssets.Image.filetypePdf
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
            if showsProgress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 150)
                    .tint(TokenColors.Icon.accent.swiftUI)
            }
        }
    }
}
