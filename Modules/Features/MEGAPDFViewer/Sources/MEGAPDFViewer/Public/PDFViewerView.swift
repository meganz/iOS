import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct PDFViewerView: View {
    public struct Dependency {
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentLoader: any PDFDocumentLoading
        let fileName: String
        /// Invoked when the user taps a link inside the document.
        let onLinkTapped: @MainActor (URL) -> Void

        public init(
            pdfDocumentSource: PDFViewerDocumentSource,
            fileName: String,
            onLinkTapped: @escaping @MainActor (URL) -> Void = { _ in }
        ) {
            self.init(
                pdfDocumentSource: pdfDocumentSource,
                documentLoader: PDFDocumentLoader(),
                fileName: fileName,
                onLinkTapped: onLinkTapped
            )
        }

        init(
            pdfDocumentSource: PDFViewerDocumentSource,
            documentLoader: some PDFDocumentLoading,
            fileName: String,
            onLinkTapped: @escaping @MainActor (URL) -> Void
        ) {
            self.pdfDocumentSource = pdfDocumentSource
            self.documentLoader = documentLoader
            self.fileName = fileName
            self.onLinkTapped = onLinkTapped
        }
    }

    @State private var viewModel: PDFViewerViewModel

    private let onLinkTapped: @MainActor (URL) -> Void

    public init(dependency: Dependency) {
        onLinkTapped = dependency.onLinkTapped
        _viewModel = State(
            initialValue: PDFViewerViewModel(
                dependency: PDFViewerViewModel.Dependency(
                    pdfDocumentSource: dependency.pdfDocumentSource,
                    documentLoader: dependency.documentLoader,
                    fileName: dependency.fileName
                )
            )
        )
    }

    public var body: some View {
        ZStack {
            TokenColors.Background.page.swiftUI
                .ignoresSafeArea()

            if let document = viewModel.pdfDocument {
                PDFDisplayerView(document: document, onLinkTapped: onLinkTapped)
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
        .task { await viewModel.loadDocumentFromSource() }
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
