import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASwift
import XCTest

/// Locks the SDK query the repository issues for each timeline operation: the filter it
/// builds, the sort order it forwards, the cursor / offset it pages with, and the scope it
/// resolves. These are the seams a second timestamp column has to move through, so they are
/// asserted explicitly rather than through the returned nodes alone.
final class MediaTimelineRepositoryTests: XCTestCase {

    private let cameraUploadHandle: MEGAHandle = 11
    private let mediaUploadHandle: MEGAHandle = 22

    // MARK: - dateSections

    func testDateSections_allLocationsNewest_buildsDayGroupedFilterInModificationDescOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .newest)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.category, .allVisualMedia)
        XCTAssertEqual(parameters.location, .cloudDriveAndVault)
        XCTAssertNil(parameters.locationHandles)
        XCTAssertNil(parameters.excludeLocationHandles)
        XCTAssertEqual(parameters.sensitivityFilter, .disabled)
        XCTAssertEqual(parameters.granularity, .day)
        XCTAssertEqual(parameters.utcOffset, expectedCurrentUTCOffset())
        XCTAssertEqual(parameters.orderType, .modificationDesc)
    }

    func testDateSections_oldest_forwardsModificationAscOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .images, location: .allLocations),
            granularity: .month,
            excludeSensitive: false,
            sortOrder: .oldest)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.orderType, .modificationAsc)
        XCTAssertEqual(parameters.category, .photo)
        XCTAssertEqual(parameters.granularity, .month)
    }

    func testDateSections_excludeSensitive_setsSensitivityFilter() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .videos, location: .allLocations),
            granularity: .year,
            excludeSensitive: true,
            sortOrder: .newest)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.sensitivityFilter, .excludeSensitive)
        XCTAssertEqual(parameters.category, .video)
    }

    func testDateSections_mapsSdkSectionsToEntities() async throws {
        let sdk = MockSdk(dateSections: [
            MockDateSection(groupId: "2026-08-21", startDate: 1_755_734_400, endDate: 1_755_820_800, count: 7)
        ])
        let sut = makeSUT(sdk: sdk)

        let sections = try await sut.dateSections(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .newest)

        XCTAssertEqual(sections, [
            MediaDateSectionEntity(
                groupId: "2026-08-21",
                startDate: Date(timeIntervalSince1970: 1_755_734_400),
                endDate: Date(timeIntervalSince1970: 1_755_820_800),
                count: 7)
        ])
    }

    // MARK: - mediaPage(after:)

    func testMediaPageAfter_firstPage_passesNoCursorAndForwardsLimit() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            after: nil,
            limit: 60)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.pagination, .cursor(nil))
        XCTAssertEqual(parameters.maxElements, 60)
        XCTAssertEqual(parameters.orderType, .modificationDesc)
        // A vacuous ascending anchor on the ordered column: its only effect is the SDK's
        // `<column> > 0` guard, which keeps timestamp-less nodes — owning no date section, and
        // filterable only after maxElements has been applied — out of the page entirely.
        XCTAssertEqual(parameters.timestampAnchorSectionOrder, .modificationAsc)
        XCTAssertEqual(parameters.timestampAnchorStartDate, 0)
        XCTAssertEqual(parameters.timestampAnchorEndDate, .max)
    }

    func testMediaPageAfter_lastNode_buildsCursorFromItsNameHandleAndModificationTime() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        let lastNode = NodeEntity(
            name: "IMG_0042.jpg",
            handle: 42,
            modificationTime: Date(timeIntervalSince1970: 1_700_000_000))

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            after: lastNode,
            limit: 20)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        guard case .cursor(let cursor) = parameters.pagination else {
            return XCTFail("expected a cursor page, got \(parameters.pagination)")
        }
        let unwrapped = try XCTUnwrap(cursor)
        XCTAssertEqual(unwrapped.lastName, "IMG_0042.jpg")
        XCTAssertEqual(unwrapped.lastHandle, 42)
        XCTAssertEqual(unwrapped.lastMtime, 1_700_000_000)
    }

    func testMediaPageAfter_returnsMappedNodes() async throws {
        let sdk = MockSdk(nodes: [
            MockNode(handle: 1, name: "a.jpg", modificationTime: Date(timeIntervalSince1970: 100)),
            MockNode(handle: 2, name: "b.mp4", modificationTime: Date(timeIntervalSince1970: 200))
        ])
        let sut = makeSUT(sdk: sdk)

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            after: nil,
            limit: 10)

        XCTAssertEqual(nodes.map(\.handle), [1, 2])
        XCTAssertEqual(nodes.map(\.name), ["a.jpg", "b.mp4"])
    }

    func testMediaPageAfter_dropsNodesWithoutAValidModificationTime() async throws {
        let sdk = MockSdk(nodes: [
            MockNode(handle: 1, name: "kept.jpg", modificationTime: Date(timeIntervalSince1970: 100)),
            MockNode(handle: 2, name: "dropped.jpg", modificationTime: Date(timeIntervalSince1970: 0))
        ])
        let sut = makeSUT(sdk: sdk)

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            after: nil,
            limit: 10)

        XCTAssertEqual(nodes.map(\.handle), [1])
    }

    // MARK: - mediaPage(before:)

    func testMediaPageBefore_newest_queriesWithFlippedOrderAndReturnsDisplayOrder() async throws {
        let sdk = MockSdk(nodes: [
            MockNode(handle: 1, name: "closest.jpg", modificationTime: Date(timeIntervalSince1970: 300)),
            MockNode(handle: 2, name: "furthest.jpg", modificationTime: Date(timeIntervalSince1970: 400))
        ])
        let sut = makeSUT(sdk: sdk)
        let firstNode = NodeEntity(
            name: "anchor.jpg",
            handle: 9,
            modificationTime: Date(timeIntervalSince1970: 200))

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            before: firstNode,
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.orderType, .modificationAsc, "backward paging must query the flipped order")
        // The flipped query walks away from the anchor, so the result is reversed back
        // into display order before it is returned.
        XCTAssertEqual(nodes.map(\.handle), [2, 1])
    }

    func testMediaPageBefore_oldest_queriesWithModificationDescOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .oldest,
            before: NodeEntity(name: "anchor.jpg", handle: 9),
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.orderType, .modificationDesc)
    }

    // MARK: - mediaWindow

    func testMediaWindow_anchorsAtSectionBoundsInSecondsAndPagesByOffset() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        let section = MediaDateSectionEntity(
            groupId: "2026-08-21",
            startDate: Date(timeIntervalSince1970: 1_755_734_400),
            endDate: Date(timeIntervalSince1970: 1_755_820_800),
            count: 40)

        _ = try await sut.mediaWindow(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            section: section,
            excludeSensitive: false,
            sortOrder: .newest,
            offset: 15,
            limit: 30)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        // Anchor bounds stay in seconds for every timestamp column; the engine scales them.
        XCTAssertEqual(parameters.timestampAnchorStartDate, 1_755_734_400)
        XCTAssertEqual(parameters.timestampAnchorEndDate, 1_755_820_800)
        XCTAssertEqual(parameters.timestampAnchorSectionOrder, .modificationDesc)
        XCTAssertEqual(parameters.orderType, .modificationDesc,
                       "the page order must match the anchor, or the page is not scoped to the bucket")
        XCTAssertEqual(parameters.pagination, .offset(15))
        XCTAssertEqual(parameters.maxElements, 30)
    }

    func testMediaWindow_oldest_anchorsInAscendingDirection() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaWindow(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            section: MediaDateSectionEntity(
                groupId: "2026-08-21",
                startDate: Date(timeIntervalSince1970: 1_755_734_400),
                endDate: Date(timeIntervalSince1970: 1_755_820_800),
                count: 40),
            excludeSensitive: false,
            sortOrder: .oldest,
            offset: 0,
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.timestampAnchorSectionOrder, .modificationAsc)
        XCTAssertEqual(parameters.orderType, .modificationAsc)
    }

    /// The guard has to name the column actually being ordered by, or it would exclude nodes on
    /// the strength of a timestamp the page does not sort on.
    func testMediaPage_guardAnchorFollowsTheOrderedColumn() async throws {
        let cases: [(MediaTimelineSortOrderEntity, MEGAListAllNodesTimestampAnchorOrder)] = [
            (.newest, .modificationAsc),
            (.oldest, .modificationAsc),
            (.newestByCaptureTime, .mediaTsAsc),
            (.oldestByCaptureTime, .mediaTsAsc)
        ]

        for (sortOrder, expectedAnchor) in cases {
            let sdk = MockSdk()
            let sut = makeSUT(sdk: sdk)

            _ = try await sut.mediaPage(
                filter: .init(mediaType: .allMedia, location: .allLocations),
                excludeSensitive: false,
                sortOrder: sortOrder,
                after: nil,
                limit: 10)

            let afterParameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
            XCTAssertEqual(afterParameters.timestampAnchorSectionOrder, expectedAnchor, "\(sortOrder)")
            XCTAssertEqual(afterParameters.timestampAnchorStartDate, 0, "\(sortOrder)")

            _ = try await sut.mediaPage(
                filter: .init(mediaType: .allMedia, location: .allLocations),
                excludeSensitive: false,
                sortOrder: sortOrder,
                before: NodeEntity(name: "anchor.jpg", handle: 9,
                                   mediaCaptureTime: Date(timeIntervalSince1970: 200)),
                limit: 10)

            let beforeParameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
            XCTAssertEqual(beforeParameters.timestampAnchorSectionOrder, expectedAnchor, "\(sortOrder)")
            XCTAssertEqual(beforeParameters.timestampAnchorStartDate, 0, "\(sortOrder)")
        }
    }

    // MARK: - Media capture time ordering

    func testDateSections_newestByCaptureTime_forwardsMediaTsDescOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .newestByCaptureTime)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.orderType, .mediaTsDesc)
        // Grouping by capture time is only accepted for a media category.
        XCTAssertEqual(parameters.category, .allVisualMedia)
    }

    func testDateSections_oldestByCaptureTime_forwardsMediaTsAscOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .images, location: .allLocations),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .oldestByCaptureTime)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.orderType, .mediaTsAsc)
    }

    /// The capture-time key is the one cursor field the SDK reads in milliseconds.
    func testMediaPageAfter_captureTimeOrder_buildsCursorFromTheCaptureTimeInMilliseconds() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        let lastNode = NodeEntity(
            name: "IMG_0042.jpg",
            handle: 42,
            modificationTime: Date(timeIntervalSince1970: 1_700_000_000),
            mediaCaptureTime: Date(timeIntervalSince1970: 1_600_000_000.25))

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newestByCaptureTime,
            after: lastNode,
            limit: 20)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.orderType, .mediaTsDesc)
        guard case .cursor(let cursor) = parameters.pagination else {
            return XCTFail("expected a cursor page, got \(parameters.pagination)")
        }
        let unwrapped = try XCTUnwrap(cursor)
        XCTAssertEqual(unwrapped.lastName, "IMG_0042.jpg")
        XCTAssertEqual(unwrapped.lastHandle, 42)
        XCTAssertEqual(unwrapped.lastMediaTsMs, 1_600_000_000_250)
        XCTAssertEqual(unwrapped.lastMtime, -1, "the modification key belongs to another order and stays unset")
    }

    func testMediaPageAfter_modificationOrder_leavesTheCaptureTimeCursorKeyUnset() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        let lastNode = NodeEntity(
            name: "IMG_0042.jpg",
            handle: 42,
            modificationTime: Date(timeIntervalSince1970: 1_700_000_000),
            mediaCaptureTime: Date(timeIntervalSince1970: 1_600_000_000))

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newest,
            after: lastNode,
            limit: 20)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        guard case .cursor(let cursor) = parameters.pagination else {
            return XCTFail("expected a cursor page, got \(parameters.pagination)")
        }
        let unwrapped = try XCTUnwrap(cursor)
        XCTAssertEqual(unwrapped.lastMtime, 1_700_000_000)
        XCTAssertEqual(unwrapped.lastMediaTsMs, -1)
    }

    /// A node with no capture time sits in no capture-time bucket, so it must not reach a page
    /// ordered by capture time — even though its modification time is perfectly valid.
    func testMediaPageAfter_captureTimeOrder_dropsNodesWithoutACaptureTime() async throws {
        let sdk = MockSdk(nodes: [
            MockNode(handle: 1, name: "kept.jpg",
                     modificationTime: Date(timeIntervalSince1970: 0),
                     mediaCaptureTime: Date(timeIntervalSince1970: 500)),
            MockNode(handle: 2, name: "dropped.jpg",
                     modificationTime: Date(timeIntervalSince1970: 100),
                     mediaCaptureTime: nil)
        ])
        let sut = makeSUT(sdk: sdk)

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newestByCaptureTime,
            after: nil,
            limit: 10)

        XCTAssertEqual(nodes.map(\.handle), [1],
                       "the drop filter must follow the column being ordered by, not the modification time")
        XCTAssertEqual(nodes.first?.mediaCaptureTime, Date(timeIntervalSince1970: 500))
    }

    func testMediaPageBefore_newestByCaptureTime_queriesWithMediaTsAscOrder() async throws {
        let sdk = MockSdk(nodes: [
            MockNode(handle: 1, name: "closest.jpg", mediaCaptureTime: Date(timeIntervalSince1970: 300)),
            MockNode(handle: 2, name: "furthest.jpg", mediaCaptureTime: Date(timeIntervalSince1970: 400))
        ])
        let sut = makeSUT(sdk: sdk)

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .newestByCaptureTime,
            before: NodeEntity(
                name: "anchor.jpg",
                handle: 9,
                mediaCaptureTime: Date(timeIntervalSince1970: 200)),
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.orderType, .mediaTsAsc,
                       "backward paging flips the direction but must stay on the same timestamp column")
        guard case .cursor(let cursor) = parameters.pagination else {
            return XCTFail("expected a cursor page, got \(parameters.pagination)")
        }
        XCTAssertEqual(try XCTUnwrap(cursor).lastMediaTsMs, 200_000)
        XCTAssertEqual(nodes.map(\.handle), [2, 1])
    }

    func testMediaPageBefore_oldestByCaptureTime_queriesWithMediaTsDescOrder() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            excludeSensitive: false,
            sortOrder: .oldestByCaptureTime,
            before: NodeEntity(name: "anchor.jpg", handle: 9,
                               mediaCaptureTime: Date(timeIntervalSince1970: 200)),
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.orderType, .mediaTsDesc)
    }

    func testMediaWindow_captureTimeOrder_anchorsOnTheCaptureTimeColumnInSeconds() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaWindow(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            section: MediaDateSectionEntity(
                groupId: "2026-08-21",
                startDate: Date(timeIntervalSince1970: 1_755_734_400),
                endDate: Date(timeIntervalSince1970: 1_755_820_800),
                count: 40),
            excludeSensitive: false,
            sortOrder: .newestByCaptureTime,
            offset: 15,
            limit: 30)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.timestampAnchorSectionOrder, .mediaTsDesc)
        XCTAssertEqual(parameters.orderType, .mediaTsDesc,
                       "the page order must match the anchor, or the page is not scoped to the bucket")
        // The anchor bounds stay in seconds even for the millisecond-valued capture time —
        // the engine scales them. Only the cursor's capture-time key is in milliseconds.
        XCTAssertEqual(parameters.timestampAnchorStartDate, 1_755_734_400)
        XCTAssertEqual(parameters.timestampAnchorEndDate, 1_755_820_800)
        XCTAssertEqual(parameters.pagination, .offset(15))
    }

    func testMediaWindow_oldestByCaptureTime_anchorsInAscendingDirection() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaWindow(
            filter: .init(mediaType: .allMedia, location: .allLocations),
            section: MediaDateSectionEntity(
                groupId: "2026-08-21",
                startDate: Date(timeIntervalSince1970: 1_755_734_400),
                endDate: Date(timeIntervalSince1970: 1_755_820_800),
                count: 40),
            excludeSensitive: false,
            sortOrder: .oldestByCaptureTime,
            offset: 0,
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.timestampAnchorSectionOrder, .mediaTsAsc)
        XCTAssertEqual(parameters.orderType, .mediaTsAsc)
    }

    // MARK: - Scope resolution

    func testDateSections_cloudDrive_excludesTheCameraUploadFolders() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.dateSections(
            filter: .init(mediaType: .allMedia, location: .cloudDrive),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .newest)

        let parameters = try XCTUnwrap(sdk.groupAllNodesByDateQueryParameters)
        XCTAssertEqual(parameters.location, .cloudDriveAndVault)
        XCTAssertNil(parameters.locationHandles)
        XCTAssertEqual(parameters.excludeLocationHandles, [cameraUploadHandle, mediaUploadHandle])
    }

    func testMediaPageAfter_cameraUploads_restrictsToTheCameraUploadFolders() async throws {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        _ = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .cameraUploads),
            excludeSensitive: false,
            sortOrder: .newest,
            after: nil,
            limit: 10)

        let parameters = try XCTUnwrap(sdk.listAllNodesByPageQueryParameters)
        XCTAssertEqual(parameters.locationHandles, [cameraUploadHandle, mediaUploadHandle])
        XCTAssertNil(parameters.excludeLocationHandles)
    }

    /// An empty include list makes the SDK fall back to the rootnode scope — i.e. the whole
    /// library, the opposite of "Camera Uploads only". The repository must short-circuit
    /// instead of querying.
    func testMediaPageAfter_cameraUploadsWithNoUploadFolders_returnsEmptyWithoutQueryingSdk() async throws {
        let sdk = MockSdk(nodes: [MockNode(handle: 1, name: "a.jpg")])
        let sut = makeSUT(sdk: sdk, cameraUploadNodeAccess: .init(), mediaUploadNodeAccess: .init())

        let nodes = try await sut.mediaPage(
            filter: .init(mediaType: .allMedia, location: .cameraUploads),
            excludeSensitive: false,
            sortOrder: .newest,
            after: nil,
            limit: 10)

        XCTAssertTrue(nodes.isEmpty)
        XCTAssertEqual(sdk.listAllNodesByPageCallCount, 0)
    }

    func testDateSections_cameraUploadsWithNoUploadFolders_returnsEmptyWithoutQueryingSdk() async throws {
        let sdk = MockSdk(dateSections: [
            MockDateSection(groupId: "2026-08-21", startDate: 1_755_734_400, endDate: 1_755_820_800, count: 7)
        ])
        let sut = makeSUT(sdk: sdk, cameraUploadNodeAccess: .init(), mediaUploadNodeAccess: .init())

        let sections = try await sut.dateSections(
            filter: .init(mediaType: .allMedia, location: .cameraUploads),
            granularity: .day,
            excludeSensitive: false,
            sortOrder: .newest)

        XCTAssertTrue(sections.isEmpty)
        XCTAssertEqual(sdk.groupAllNodesByDateCallCount, 0)
    }

    // MARK: - mediaNodeUpdates

    func testMediaNodeUpdates_emitsOnlyVisualMediaAndDropsEmptyBatches() async throws {
        let updates = [
            [NodeEntity(name: "doc.pdf", handle: 1)],
            [NodeEntity(name: "a.jpg", handle: 2), NodeEntity(name: "notes.txt", handle: 3)]
        ]
        let stream = AsyncStream<[NodeEntity]> { continuation in
            updates.forEach { continuation.yield($0) }
            continuation.finish()
        }
        let sut = makeSUT(
            nodeUpdatesProvider: MockNodeUpdatesProvider(
                nodeUpdates: stream.eraseToAnyAsyncSequence()))

        var emitted: [[MEGAHandle]] = []
        for await nodes in sut.mediaNodeUpdates() {
            emitted.append(nodes.map(\.handle))
        }

        XCTAssertEqual(emitted, [[2]], "the pdf-only batch must be dropped, and the txt filtered out")
    }

    // MARK: - Helpers

    private func makeSUT(
        sdk: MockSdk = MockSdk(),
        cameraUploadNodeAccess: MockNodeAccess? = nil,
        mediaUploadNodeAccess: MockNodeAccess? = nil,
        nodeUpdatesProvider: MockNodeUpdatesProvider = MockNodeUpdatesProvider()
    ) -> MediaTimelineRepository {
        MediaTimelineRepository(
            sdk: sdk,
            cameraUploadNodeAccess: cameraUploadNodeAccess
                ?? MockNodeAccess(result: .success(MockNode(handle: cameraUploadHandle))),
            mediaUploadNodeAccess: mediaUploadNodeAccess
                ?? MockNodeAccess(result: .success(MockNode(handle: mediaUploadHandle))),
            nodeUpdatesProvider: nodeUpdatesProvider)
    }

    /// The ISO-8601 offset the repository is expected to hand the fixed-offset SDK API.
    private func expectedCurrentUTCOffset() -> String {
        let seconds = TimeZone.current.secondsFromGMT()
        let sign = seconds < 0 ? "-" : "+"
        let totalMinutes = abs(seconds) / 60
        return String(format: "%@%02d:%02d", sign, totalMinutes / 60, totalMinutes % 60)
    }
}
