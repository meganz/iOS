@testable import MEGA
import MEGADomain
import MEGAL10n
@testable import Search
import Testing

extension NodeSource {
    static func testBucket(
        parentNodeName: String = "Node",
        isUpdate: Bool = false,
        timestamp: Date = .init()
    ) -> NodeSource {
        NodeSource.recentActionBucket(
            MockRecentActionBucketTrampoline(
                isUpdate: isUpdate,
                parentNodeToReturn: NodeEntity(name: parentNodeName),
                timestamp: timestamp
            )
        )
    }
}

@Suite("RecentListHeaderViewModel Factory")
struct RecentListHeaderViewModelFactoryTests {
    struct Harness {
        let sut = RecentListHeaderViewModelFactory(
            calendar: .testCalendar,
            mediumStyleFormatter: { _ in "FormattedDate_BeforeYesterday" }
        )
        func result(_ nodeSource: NodeSource) -> ListHeaderViewModel? {
            sut.buildIfNeeded(for: nodeSource)
        }
    }
    
    @Suite("Check if value present")
    struct Optionality {
        @Test("Returns nil for non-recent nodeSource")
        func nonRecentNodeSource() {
            let harness = Harness()
            #expect(harness.result(NodeSource.testNode) == nil)
        }
        
        @Test("Returns non-nil for recent nodeSource")
        func nonNilRecentNodeSource() {
            let harness = Harness()
            #expect(harness.result(NodeSource.mockRecentActionBucketEmpty) != nil)
        }

    }
    
    @Suite("Leading text value")
    struct Leading {
        @Test("Text has uppercased parent node name and a dot")
        func textFormatting() throws {
            let harness = Harness()
            let result = try #require(harness.result(.testBucket(parentNodeName: "Parent")))
            #expect(result.leadingText == "PARENT •")
        }
    }
    
    @Suite("Icon image value")
    struct Icon {
        @Test("Image is 'versioned'")
        func bucketIsUpdate() throws {
            let harness = Harness()
            let result = try #require(
                harness.result(
                    .testBucket(isUpdate: true)
                )
            )
            #expect(result.icon == UIImage.versioned)
        }
        
        @Test("Image is 'recentUpload'")
        func bucketIsRecentUpdate() throws {
            let harness = Harness()
            let result = try #require(
                harness.result(
                    .testBucket(isUpdate: false)
                )
            )
            #expect(result.icon == UIImage.recentUpload)
        }
    }
    
    @Suite("Trailing text value")
    struct Trailing {
        @Test("Date is today, text is 'TODAY'")
        func timestampToday() throws {
            let harness = Harness()
            let result = try #require(
                harness.result(
                    .testBucket(timestamp: Date())
                )
            )
            #expect(result.trailingText == Strings.Localizable.today.uppercased())
        }
        
        @Test("Date is yesterday, text is 'YESTERDAY'")
        func timestampYesterday() throws {
            let harness = Harness()
            let yesterday = try #require(
                Calendar.testCalendar.date(
                    byAdding: .init(day: -1),
                    to: Date()
                )
            )
            let result = try #require(
                harness.result(
                    .testBucket(timestamp: yesterday)
                )
            )
            #expect(result.trailingText == Strings.Localizable.yesterday.uppercased())
        }
        
        @Test("Date is before yesterday, text is formatted and uppercased'")
        func timestampBeforeYesterday() throws {
            let harness = Harness()
            let date = try #require(
                Calendar.testCalendar.date(
                    byAdding: .init(day: -2),
                    to: Date()
                )
            )
            let result = try #require(
                harness.result(
                    .testBucket(timestamp: date)
                )
            )
            #expect(result.trailingText == "FORMATTEDDATE_BEFOREYESTERDAY")
        }
    }
}
