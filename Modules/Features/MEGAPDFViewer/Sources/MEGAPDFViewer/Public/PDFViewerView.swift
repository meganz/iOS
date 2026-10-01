import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

public struct PDFViewerView: View {
    public struct Dependency {
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentURLUseCase: any PDFDocumentURLUseCaseProtocol
        let documentLoader: any PDFDocumentLoading
        let fileName: String
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let onClose: @MainActor () -> Void
        /// Invoked when the user taps a link inside the document.
        let onLinkTapped: @MainActor (URL) -> Void

        public init(
            pdfDocumentSource: PDFViewerDocumentSource,
            downloadUseCase: some DownloadNodeUseCaseProtocol,
            fileName: String,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            onClose: @escaping @MainActor () -> Void,
            onLinkTapped: @escaping @MainActor (URL) -> Void = { _ in }
        ) {
            self.init(
                pdfDocumentSource: pdfDocumentSource,
                documentURLUseCase: PDFDocumentURLUseCase(downloadUseCase: downloadUseCase),
                documentLoader: PDFDocumentLoader(),
                fileName: fileName,
                transferIndicatorToolbarFactory: transferIndicatorToolbarFactory,
                onClose: onClose,
                onLinkTapped: onLinkTapped
            )
        }

        init(
            pdfDocumentSource: PDFViewerDocumentSource,
            documentURLUseCase: some PDFDocumentURLUseCaseProtocol,
            documentLoader: some PDFDocumentLoading,
            fileName: String,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            onClose: @escaping @MainActor () -> Void,
            onLinkTapped: @escaping @MainActor (URL) -> Void
        ) {
            self.pdfDocumentSource = pdfDocumentSource
            self.documentURLUseCase = documentURLUseCase
            self.documentLoader = documentLoader
            self.fileName = fileName
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
            self.onClose = onClose
            self.onLinkTapped = onLinkTapped
        }
    }

    @State private var viewModel: PDFViewerViewModel
    @State private var retryTask: Task<Void, Never>?

    private let onClose: @MainActor () -> Void

    private let onLinkTapped: @MainActor (URL) -> Void

    private let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory

    public init(dependency: Dependency) {
        onClose = dependency.onClose
        onLinkTapped = dependency.onLinkTapped
        transferIndicatorToolbarFactory = dependency.transferIndicatorToolbarFactory
        _viewModel = State(
            initialValue: PDFViewerViewModel(
                dependency: PDFViewerViewModel.Dependency(
                    pdfDocumentSource: dependency.pdfDocumentSource,
                    documentURLUseCase: dependency.documentURLUseCase,
                    documentLoader: dependency.documentLoader,
                    fileName: dependency.fileName
                )
            )
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
                        onLinkTapped: onLinkTapped,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isChromeHidden.toggle()
                            }
                        }
                    )
                    .ignoresSafeArea()
                    // Makes Liquid Glass navbar/toolbar appearance update more
                    // likely when dismissing thumbnails view.
                    .opacity(viewModel.isShowingThumbnails ? 0 : 1)

                    if viewModel.isShowingThumbnails {
                        PDFThumbnailGridView(
                            document: document,
                            currentPage: viewModel.currentPageIndex
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
                case .ready:
                    EmptyView()
                }
            }
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
        }
        .tint(TokenColors.Icon.primary.swiftUI)
        .task { await viewModel.loadDocumentFromSource() }
        .onDisappear {
            retryTask?.cancel()
            retryTask = nil
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                onClose()
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

        // Trailing items lay out in the order they are declared, so the
        // indicator goes first and the more button keeps the trailing edge.
        transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)

        ToolbarItem(placement: .topBarTrailing) {
            Button {} label: {
                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
            }
            .accessibilityLabel(Strings.Localizable.more)
        }

        if viewModel.state.isReady {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: TokenSpacing._7) {
                    Button {} label: {
                        MEGAAssets.Image.listSmallMediumThinSolid
                    }
                    .accessibilityLabel(Strings.Localizable.PdfPreview.contents)

                    PDFThumbnailsToggleView(
                        isActive: viewModel.isShowingThumbnails
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.isShowingThumbnails.toggle()
                        }
                    }
                }
                .padding(.horizontal, TokenSpacing._2 + TokenSpacing._1)

                Spacer()

                Button {} label: {
                    Image(uiImage: MEGAAssets.UIImage.searchSmall)
                }
                .accessibilityLabel(Strings.Localizable.search)
            }
        }
    }

    private func loadingView(progress: Float?) -> some View {
        VStack(spacing: TokenSpacing._6) {
            MEGAAssets.Image.filetypePdf
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 150)
                .tint(TokenColors.Icon.accent.swiftUI)
        }
    }
}
