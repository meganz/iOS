import MEGADomain
import XCTest

/// The timeline order carries two independent axes — direction and timestamp column — and the
/// repository derives the SDK order, the anchor direction and the cursor key from them, so the
/// composition is pinned here.
final class MediaTimelineSortOrderEntityMapperTests: XCTestCase {

    func testToMediaTimelineSortOrderEntity_defaultBasis_keepsModificationTime() {
        XCTAssertEqual(SortOrderEntity.modificationDesc.toMediaTimelineSortOrderEntity(), .newest)
        XCTAssertEqual(SortOrderEntity.modificationAsc.toMediaTimelineSortOrderEntity(), .oldest)
    }

    /// Any order the timeline cannot honour — including the `.none` fallback and a "same for
    /// all" order set by another screen — shows as newest-first, matching its sort menu.
    func testToMediaTimelineSortOrderEntity_unsupportedOrders_collapseToNewest() {
        for sortOrder in [SortOrderEntity.none, .defaultAsc, .sizeAsc, .labelDesc, .favouriteAsc] {
            XCTAssertEqual(sortOrder.toMediaTimelineSortOrderEntity(), .newest, "\(sortOrder)")
        }
    }

    func testToMediaTimelineSortOrderEntity_captureTimeBasis_keepsTheDirection() {
        XCTAssertEqual(
            SortOrderEntity.modificationDesc.toMediaTimelineSortOrderEntity(basis: .mediaCaptureTime),
            .newestByCaptureTime)
        XCTAssertEqual(
            SortOrderEntity.modificationAsc.toMediaTimelineSortOrderEntity(basis: .mediaCaptureTime),
            .oldestByCaptureTime)
    }

    func testTimestampBasis_matchesTheOrder() {
        XCTAssertEqual(MediaTimelineSortOrderEntity.newest.timestampBasis, .modificationTime)
        XCTAssertEqual(MediaTimelineSortOrderEntity.oldest.timestampBasis, .modificationTime)
        XCTAssertEqual(MediaTimelineSortOrderEntity.newestByCaptureTime.timestampBasis, .mediaCaptureTime)
        XCTAssertEqual(MediaTimelineSortOrderEntity.oldestByCaptureTime.timestampBasis, .mediaCaptureTime)
    }

    func testIsNewestFirst_matchesTheDirection() {
        XCTAssertTrue(MediaTimelineSortOrderEntity.newest.isNewestFirst)
        XCTAssertTrue(MediaTimelineSortOrderEntity.newestByCaptureTime.isNewestFirst)
        XCTAssertFalse(MediaTimelineSortOrderEntity.oldest.isNewestFirst)
        XCTAssertFalse(MediaTimelineSortOrderEntity.oldestByCaptureTime.isNewestFirst)
    }

    func testApplyingBasis_switchesColumnAndKeepsDirection() {
        XCTAssertEqual(MediaTimelineSortOrderEntity.newest.applying(.mediaCaptureTime), .newestByCaptureTime)
        XCTAssertEqual(MediaTimelineSortOrderEntity.oldestByCaptureTime.applying(.modificationTime), .oldest)
        XCTAssertEqual(MediaTimelineSortOrderEntity.newest.applying(.modificationTime), .newest)
    }

    /// Backward keyset paging queries the flipped direction — but must stay on the same column,
    /// or the page would come from a different ordering entirely.
    func testFlippingDirection_keepsTheTimestampColumn() {
        XCTAssertEqual(MediaTimelineSortOrderEntity.newest.flippingDirection, .oldest)
        XCTAssertEqual(MediaTimelineSortOrderEntity.oldest.flippingDirection, .newest)
        XCTAssertEqual(MediaTimelineSortOrderEntity.newestByCaptureTime.flippingDirection, .oldestByCaptureTime)
        XCTAssertEqual(MediaTimelineSortOrderEntity.oldestByCaptureTime.flippingDirection, .newestByCaptureTime)
    }

    func testInit_composesEveryDirectionAndBasisCombination() {
        for basis in MediaTimelineSortOrderEntity.TimestampBasis.allCases {
            for newestFirst in [true, false] {
                let sortOrder = MediaTimelineSortOrderEntity(newestFirst: newestFirst, basis: basis)
                XCTAssertEqual(sortOrder.isNewestFirst, newestFirst)
                XCTAssertEqual(sortOrder.timestampBasis, basis)
            }
        }
    }
}
