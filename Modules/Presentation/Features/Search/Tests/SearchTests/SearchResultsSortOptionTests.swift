@testable import Search
import SwiftUI
import Testing

struct SearchResultsSortOptionTests {
    @Test func testInit() {
        let sut = SearchResultsSortOption(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:])
        #expect(sut.sortOrder == .init(key: .name))
        #expect(sut.title == "Name")
        #expect(sut.iconsByDirection == [:])
    }

    @Test func testRemoveIcon() {
        let sut = SearchResultsSortOption(
            sortOrder: .init(key: .name),
            title: "Name",
            iconsByDirection: [.ascending: Image(systemName: "plus"), .descending: Image(systemName: "minus")]
        )
        let updatedSortOption = sut.removeIcon()
        #expect(updatedSortOption.sortOrder == .init(key: .name))
        #expect(updatedSortOption.title == "Name")
        #expect(updatedSortOption.iconsByDirection == [:])
    }
}
