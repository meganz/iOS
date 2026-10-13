@testable import MEGAPDFViewer

struct MockPDFNearestOutlineItemUseCase: PDFNearestOutlineItemUseCaseProtocol {
    let result: PDFOutlineItem?

    init(result: PDFOutlineItem? = nil) {
        self.result = result
    }

    func activeItem(
        forPageIndex pageIndex: Int,
        in pageSortedItems: [PDFOutlineItem]
    ) -> PDFOutlineItem? {
        result
    }
}
