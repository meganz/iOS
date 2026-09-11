@testable import ContentLibraries
import Foundation
import MEGADomain
import MEGADomainMock

enum PaginationTestError: Error {
    case pageFailed
}

/// Six nodes in newest-first display order: `photoA` carries the newest modification time,
/// `photoF` the oldest, and the handles run 1...6 so an assertion on `map(\.handle)` reads as the
/// order itself.
extension NodeEntity {
    static let photoA = testNode(handle: 1)
    static let photoB = testNode(handle: 2)
    static let photoC = testNode(handle: 3)
    static let photoD = testNode(handle: 4)
    static let photoE = testNode(handle: 5)
    static let photoF = testNode(handle: 6)

    static func testNode(handle: HandleEntity, secondsFromEpoch: TimeInterval? = nil) -> NodeEntity {
        NodeEntity(
            name: "node-\(handle)",
            handle: handle,
            modificationTime: Date(timeIntervalSince1970: secondsFromEpoch ?? Double(10_000 - handle * 100)))
    }
}

func makePaginationContext(
    nodes: [NodeEntity],
    globalStartIndex: Int = 0,
    totalCount: Int = 0,
    sortOrder: MediaTimelineSortOrderEntity = .newest
) -> PhotoBrowserPaginationContext {
    PhotoBrowserPaginationContext(
        nodes: nodes,
        globalStartIndex: globalStartIndex,
        totalCount: totalCount,
        filter: MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations),
        sortOrder: sortOrder)
}

@MainActor
func makePaginatorSUT(
    initial: [NodeEntity],
    globalStartIndex: Int = 0,
    totalCount: Int = 0,
    sortOrder: MediaTimelineSortOrderEntity = .newest,
    forward: [Result<[NodeEntity], any Error>] = [],
    backward: [Result<[NodeEntity], any Error>] = [],
    pageSize: Int = PhotoBrowserPaginator.defaultPageSize
) -> (PhotoBrowserPaginator, MediaTimelinePageScript) {
    let script = MediaTimelinePageScript(forward: forward, backward: backward)
    let sut = PhotoBrowserPaginator(
        context: makePaginationContext(
            nodes: initial,
            globalStartIndex: globalStartIndex,
            totalCount: totalCount,
            sortOrder: sortOrder),
        useCase: StubMediaTimelineUseCase(script: script),
        pageSize: pageSize)
    return (sut, script)
}
