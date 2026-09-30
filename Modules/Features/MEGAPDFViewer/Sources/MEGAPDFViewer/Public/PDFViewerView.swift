import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
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
                        onLinkTapped: onLinkTapped
                    )
                    .ignoresSafeArea()
                }

                switch viewModel.state {
                case .loading(let progress):
                    loadingView(progress: progress)
                case .failed:
                    failedView
                case .ready:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbarContent }
            .transparentLiquidGlassOrSolidOtherwiseToolbarBackground(for: .navigationBar)
            .transparentLiquidGlassOrSolidOtherwiseToolbarBackground(for: .bottomBar)
        }
        .tint(TokenColors.Icon.primary.swiftUI)
        .task { await viewModel.loadDocumentFromSource() }
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

        if viewModel.state != .failed {
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
        }

        if viewModel.state.isReady {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {} label: {
                    MEGAAssets.Image.listSmallMediumThinSolid
                }
                .accessibilityLabel(Strings.Localizable.PdfPreview.contents)

                // Will be configured with thumbnail toggle state and handling
                // in an upcoming MR.
                PDFThumbnailsToggleView(isActive: false) {}

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

    /// IOS-12492 will provide a generic fullscreen error view, and replace this
    /// question-mark view with the error view.
    private var failedView: some View {
        Image(systemName: "doc.questionmark")
            .font(.system(size: 44))
            .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
    }
}
