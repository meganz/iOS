@testable import MEGAPDFViewer
import Testing

struct PDFNearestOutlineItemUseCaseTests {
    private let sut = PDFNearestOutlineItemUseCase()

    @Test func emptyOutline_returnsNil() {
        #expect(sut.activeItem(forPageIndex: 5, in: []) == nil)
    }

    @Test func beforeFirstItem_returnsNil() {
        #expect(sut.activeItem(forPageIndex: 1, in: [item("0", page: 3)]) == nil)
    }

    @Test func exactFirstPage_returnsFirstItem() {
        #expect(sut.activeItem(forPageIndex: 0, in: [
            item("0", page: 0), item("1", page: 4)
        ]) == item("0", page: 0))
    }

    @Test func betweenItems_returnsClosestPreceding() {
        #expect(sut.activeItem(forPageIndex: 5, in: [
            item("0", page: 0), item("1", page: 4), item("2", page: 8)
        ]) == item("1", page: 4))
    }

    @Test func afterLastItem_returnsLastItem() {
        #expect(sut.activeItem(forPageIndex: 12, in: [
            item("0", page: 0), item("1", page: 4), item("2", page: 8)
        ]) == item("2", page: 8))
    }

    @Test func samePage_returnsLaterItem() {
        #expect(sut.activeItem(forPageIndex: 5, in: [
            item("0", page: 0), item("1", page: 5), item("2", page: 5)
        ]) == item("2", page: 5))
    }

    @Test func largeOutline_returnsCorrectBoundary() {
        let items = (0..<20_000).map { item("\($0)", page: $0) }

        #expect(sut.activeItem(forPageIndex: 9_999, in: items) == items[9_999])
    }

    @Test func unsortedMetadata_usesPageOrderForIntermediatePage() {
        let items = PDFOutlineItems(
            inOutlineOrder: [
                item("30", page: 30), item("0", page: 0), item("10", page: 10)
            ],
            inPageOrder: [
                item("0", page: 0), item("10", page: 10), item("30", page: 30)
            ]
        )

        let activeItem = sut.activeItem(
            forPageIndex: 15,
            in: items.inPageOrder
        )

        #expect(activeItem == item("10", page: 10))
    }

    @Test func unsortedMetadata_usesPageOrderAfterLastItem() {
        let items = PDFOutlineItems(
            inOutlineOrder: [
                item("10", page: 10), item("0", page: 0), item("30", page: 30)
            ],
            inPageOrder: [
                item("0", page: 0), item("10", page: 10), item("30", page: 30)
            ]
        )

        let activeItem = sut.activeItem(
            forPageIndex: 35,
            in: items.inPageOrder
        )

        #expect(activeItem == item("30", page: 30))
    }

    @Test func unsortedMetadata_usesStablePageOrderForSamePageTie() {
        let items = PDFOutlineItems(
            inOutlineOrder: [
                item("30", page: 30),
                item("10a", page: 10),
                item("0", page: 0),
                item("10b", page: 10)
            ],
            inPageOrder: [
                item("0", page: 0),
                item("10a", page: 10),
                item("10b", page: 10),
                item("30", page: 30)
            ]
        )

        let activeItem = sut.activeItem(
            forPageIndex: 10,
            in: items.inPageOrder
        )

        #expect(activeItem == item("10b", page: 10))
    }

    @Test(arguments: [
        [
            PDFOutlineItem(id: "30", title: "30", level: 0, pageIndex: 30),
            PDFOutlineItem(id: "0", title: "0", level: 0, pageIndex: 0),
            PDFOutlineItem(id: "10", title: "10", level: 0, pageIndex: 10)
        ],
        [
            PDFOutlineItem(id: "10", title: "10", level: 0, pageIndex: 10),
            PDFOutlineItem(id: "30", title: "30", level: 0, pageIndex: 30),
            PDFOutlineItem(id: "0", title: "0", level: 0, pageIndex: 0)
        ],
        [
            PDFOutlineItem(id: "10a", title: "10a", level: 0, pageIndex: 10),
            PDFOutlineItem(id: "0", title: "0", level: 0, pageIndex: 0),
            PDFOutlineItem(id: "30", title: "30", level: 0, pageIndex: 30),
            PDFOutlineItem(id: "10b", title: "10b", level: 0, pageIndex: 10)
        ]
    ] as [[PDFOutlineItem]])
    func unsortedPageOrder_terminates(items: [PDFOutlineItem]) {
        searchTerminates(for: items)
    }

    // Unsorted outline cases are just to confirm that the search still
    // converges. The return value can be expected to be nonsense when the
    // input array isn't sorted.
    private func searchTerminates(for items: [PDFOutlineItem]) {
        _ = PDFNearestOutlineItemUseCase().activeItem(
            forPageIndex: 15,
            in: items
        )
    }

    private func item(_ id: String, page: Int) -> PDFOutlineItem {
        PDFOutlineItem(id: id, title: id, level: 0, pageIndex: page)
    }
}
