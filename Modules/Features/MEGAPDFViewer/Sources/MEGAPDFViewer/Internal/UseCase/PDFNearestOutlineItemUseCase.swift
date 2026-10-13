protocol PDFNearestOutlineItemUseCaseProtocol: Sendable {
    /// Returns the last item at or before `pageIndex` from sorted input.
    /// - Unsorted input still converges but can return an incorrect item.
    func activeItem(
        forPageIndex pageIndex: Int,
        in pageSortedItems: [PDFOutlineItem]
    ) -> PDFOutlineItem?
}

struct PDFNearestOutlineItemUseCase: PDFNearestOutlineItemUseCaseProtocol {
    func activeItem(
        forPageIndex pageIndex: Int,
        in pageSortedItems: [PDFOutlineItem]
    ) -> PDFOutlineItem? {
        var lowerBound = 0
        var upperBound = pageSortedItems.count

        while lowerBound < upperBound {
            let middleIndex = lowerBound + (upperBound - lowerBound) / 2
            if pageSortedItems[middleIndex].pageIndex <= pageIndex {
                lowerBound = middleIndex + 1
            } else {
                upperBound = middleIndex
            }
        }
        return lowerBound == 0 ? nil : pageSortedItems[lowerBound - 1]
    }
}
