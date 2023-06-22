@testable import MEGA
import XCTest

final class ElementStoreTests: XCTestCase {
    private struct Item: Equatable {
        let key: Int
        let value: String
    }
    
    private static func store(currentIndex i: Int = 0, elements items: [Item] = [], elementsIdentifiedBy path: KeyPath<Item, Int>) -> ElementStore<Item, Int> {
        ElementStore(currentIndex: i, elements: items, elementsIdentifiedBy: path)
    }
    
    func testInitialise_withoutParameters_shouldDefaultProperties() async throws {
        let emptyStore = Self.store(elementsIdentifiedBy: \.key)
        let currentIndex = await emptyStore.currentIndex
        let isEmpty = await emptyStore.isEmpty
        let count = await emptyStore.count
        let current = await emptyStore.current
        XCTAssertEqual(currentIndex, 0)
        XCTAssertTrue(isEmpty)
        XCTAssertEqual(count, 0)
        XCTAssertNil(current)
    }
    
    func testInitialise_withParameters_shouldSetValues() async throws {
        let expectedItem = Item(key: 22, value: "bb")
        let items = [
            Item(key: 11, value: "a"),
            expectedItem,
            Item(key: 33, value: "ccc")
        ]
        let validStore = Self.store(currentIndex: 1, elements: items, elementsIdentifiedBy: \.key)
        
        let currentIndex = await validStore.currentIndex
        let isEmpty = await validStore.isEmpty
        let count = await validStore.count
        let current = await validStore.current
        XCTAssertEqual(currentIndex, 1)
        XCTAssertFalse(isEmpty)
        XCTAssertEqual(count, 3)
        XCTAssertEqual(current, expectedItem)
    }
    
    func testInitialise_withParametersAndDuplicateIDs_shouldKeepNewestButInsertAtOriginalIndex() async throws {
        let expectedRemovedItem = Item(key: 11, value: "aa")
        let duplicateKeyedItem = Item(key: 11, value: "dddd")
        let items = [
            expectedRemovedItem,
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc"),
            duplicateKeyedItem
        ]
        let duplicatedPairStore = Self.store(elements: items, elementsIdentifiedBy: \.key)
        let currentIndex = await duplicatedPairStore.currentIndex
        let isEmpty = await duplicatedPairStore.isEmpty
        let count = await duplicatedPairStore.count
        let current = await duplicatedPairStore.current
        XCTAssertEqual(currentIndex, 0)
        XCTAssertFalse(isEmpty)
        XCTAssertEqual(count, 3)
        XCTAssertEqual(current, duplicateKeyedItem)
    }
    
    func testInitialise_withNegativeIndex_shouldSetDefaultIndex() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        let minIndexStore = Self.store(currentIndex: Int.min, elements: items, elementsIdentifiedBy: \.key)
        let currentIndex = await minIndexStore.currentIndex
        let current = await minIndexStore.current
        XCTAssertEqual(currentIndex, 0)
        XCTAssertEqual(current, items.first)
    }
    
    func testInitialise_withOutOfBoundsIndex_shouldSetDefaultIndex() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        let maxIndexStore = Self.store(currentIndex: Int.max, elements: items, elementsIdentifiedBy: \.key)
        let currentIndex = await maxIndexStore.currentIndex
        let current = await maxIndexStore.current
        XCTAssertEqual(currentIndex, 0)
        XCTAssertEqual(current, items.first)
    }
    
    func testRemoveOneItem_fromEmptyStore_shouldNotChangeProperties() async throws {
        let store = Self.store(elementsIdentifiedBy: \.key)
        let item = Item(key: 11, value: "a")
        await store.remove([item])
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let currentIndex = await store.currentIndex
                let isEmpty = await store.isEmpty
                let count = await store.count
                let current = await store.current
                XCTAssertEqual(currentIndex, 0)
                XCTAssertTrue(isEmpty)
                XCTAssertEqual(count, 0)
                XCTAssertNil(current)
            }
        }
    }
        
    func testRemoveNoItems_fromStore_shouldNotChangeProperties() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        let store = Self.store(currentIndex: 0, elements: items, elementsIdentifiedBy: \.key)
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await store.remove([])
                let currentIndex = await store.currentIndex
                let isEmpty = await store.isEmpty
                let count = await store.count
                let current = await store.current
                XCTAssertEqual(currentIndex, 0)
                XCTAssertFalse(isEmpty)
                XCTAssertEqual(count, 3)
                XCTAssertEqual(current, items.first)
            }
        }
    }
    
    func testRemoveOneItemIteratively_inDescendingOrder_shouldDecrementIndexAndReturnRemainingItems() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        let startCount = items.count
        var i = 1
        let store = Self.store(currentIndex: startCount - 1, elements: items, elementsIdentifiedBy: \.key)
        
        while let lastItem = await store.current {
            let remainingItems = await store.remove([lastItem])
            let currentIndex = await store.currentIndex
            let isEmpty = await store.isEmpty
            let count = await store.count
            
            XCTAssertEqual(currentIndex, startCount - i)
            XCTAssertEqual(isEmpty, i == startCount)
            XCTAssertEqual(count, startCount - i)
            XCTAssertEqual(remainingItems, Array(items.prefix(startCount - i)))
            i += 1
        }
    }
    
    func testRemoveOneItemIteratively_inAscendingOrder_shouldNotChangeIndexAndReturnRemainingItems() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        let startCount = items.count
        var i = 1
        let store = Self.store(elements: items, elementsIdentifiedBy: \.key)
        
        while let firstItem = await store.current {
            let remainingItems = await store.remove([firstItem])
            let currentIndex = await store.currentIndex
            let isEmpty = await store.isEmpty
            let count = await store.count
            
            XCTAssertEqual(currentIndex, 0)
            XCTAssertEqual(isEmpty, i == startCount)
            XCTAssertEqual(count, startCount - i)
            XCTAssertEqual(remainingItems, Array(items.suffix(startCount - i)))
            i += 1
        }
    }
    
    func testRemoveConsecutiveItems_inAscendingOrderIteratively_shouldRemoveAllTargetItems() async throws {
        let items = [
            Item(key: 11, value: "a"),
            Item(key: 22, value: "bb"),
            Item(key: 33, value: "ccc")
        ]
        var i = 1
        while i < items.count {
            let store = Self.store(elements: items, elementsIdentifiedBy: \.key)
            let targetItems = Array(items.prefix(i))
            let remainingItems = await store.remove(targetItems)
            let currentIndex = await store.currentIndex
            let isEmpty = await store.isEmpty
            let count = await store.count
            targetItems.forEach {
                XCTAssertFalse(remainingItems.contains($0))
            }
            XCTAssertEqual(currentIndex, 0)
            XCTAssertEqual(isEmpty, i == items.count)
            XCTAssertEqual(count, items.count - i)
            i += 1
        }
    }

}
