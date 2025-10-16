@testable import Search
import Testing

struct SearchResultsSortOptionsViewModelTests {
    @Test func testInit() {
        let sortOption = SearchResultsSortOption(
            sortOrder: .init(key: .name),
            title: "Name",
            iconsByDirection: [:]
        )
        let title = "Sort by"
        let sut = SearchResultsSortOptionsViewModel(title: title, sortOptions: [sortOption])

        #expect(sut.title == title)
        #expect(sut.sortOptions.first?.sortOrder == .init(key: .name))
        #expect(sut.sortOptions.first?.title == "Name")
        #expect(sut.sortOptions.first?.iconsByDirection == [:])
    }

    @Test func testMakeNewViewModel() {
        let title = "Sort by"
        let sut = SearchResultsSortOptionsViewModel(title: title, sortOptions: [])
        let sortOption = SearchResultsSortOption(
            sortOrder: .init(key: .name),
            title: "Name",
            iconsByDirection: [:]
        )
        let updatedViewModel = sut.makeNewViewModel(with: [sortOption], tapHandler: nil)
        #expect(updatedViewModel.title == title)
        #expect(updatedViewModel.sortOptions.first?.sortOrder == .init(key: .name))
        #expect(updatedViewModel.sortOptions.first?.title == "Name")
        #expect(updatedViewModel.sortOptions.first?.iconsByDirection == [:])
    }
}
