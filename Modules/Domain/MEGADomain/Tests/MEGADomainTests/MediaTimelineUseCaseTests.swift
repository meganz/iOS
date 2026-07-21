import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MediaTimelineUseCaseTests: XCTestCase {

    private let filter = MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations)

    func testDateSections_returnsRepositorySections() async throws {
        let sections = makeSections()
        let sut = makeSUT(repository: MockMediaTimelineRepository(dateSectionsResult: .success(sections)))

        let result = try await sut.dateSections(filter: filter, granularity: .month, sortOrder: .newest)

        XCTAssertEqual(result, sections)
    }

    func testMediaPage_returnsRepositoryNodes() async throws {
        let nodes = [NodeEntity(name: "a.jpg", handle: 1), NodeEntity(name: "b.mp4", handle: 2)]
        let sut = makeSUT(repository: MockMediaTimelineRepository(mediaPageResult: .success(nodes)))

        let result = try await sut.mediaPage(filter: filter, sortOrder: .newest, after: nil, limit: 50)

        XCTAssertEqual(result, nodes)
    }

    func testMediaPageBefore_returnsRepositoryNodes() async throws {
        let nodes = [NodeEntity(name: "x.jpg", handle: 7), NodeEntity(name: "y.jpg", handle: 8)]
        let sut = makeSUT(repository: MockMediaTimelineRepository(mediaPageBeforeResult: .success(nodes)))

        let result = try await sut.mediaPage(
            filter: filter, sortOrder: .newest, before: NodeEntity(name: "z.jpg", handle: 9), limit: 50)

        XCTAssertEqual(result, nodes)
    }

    func testMediaWindow_returnsRepositoryNodes() async throws {
        let nodes = [NodeEntity(name: "c.jpg", handle: 3)]
        let sut = makeSUT(repository: MockMediaTimelineRepository(mediaWindowResult: .success(nodes)))

        let result = try await sut.mediaWindow(
            filter: filter, section: makeSections()[0], sortOrder: .newest, offset: 20, limit: 30)

        XCTAssertEqual(result, nodes)
    }

    func testMonitorDateSections_emitsInitialSectionsThenReEmitsOnNodeUpdate() async throws {
        let sections = makeSections()
        let repository = MockMediaTimelineRepository(
            nodeUpdates: makeUpdatesSequence([[NodeEntity(name: "new.jpg", handle: 9)]]),
            dateSectionsResult: .success(sections))
        let sut = makeSUT(repository: repository)

        var iterator = await sut.monitorDateSections(
            filter: filter, granularity: .month, sortOrder: .newest).makeAsyncIterator()

        let initial = try await iterator.next()?.get()
        let afterUpdate = try await iterator.next()?.get()

        XCTAssertEqual(initial, sections)
        XCTAssertEqual(afterUpdate, sections)
    }

    func testMonitorDateSections_reEmitsOnFolderSensitivityChange() async throws {
        let sections = makeSections()
        let sut = makeSUT(
            repository: MockMediaTimelineRepository(dateSectionsResult: .success(sections)),
            folderSensitivityChanged: makeVoidSequence(count: 1))

        var iterator = await sut.monitorDateSections(
            filter: filter, granularity: .month, sortOrder: .newest).makeAsyncIterator()

        let initial = try await iterator.next()?.get()
        let afterSensitivityChange = try await iterator.next()?.get()

        XCTAssertEqual(initial, sections)
        XCTAssertEqual(afterSensitivityChange, sections)
    }

    func testExcludeSensitives_forwardsAccountPreference() async {
        let excluded = await makeSUT(excludeSensitives: true).excludeSensitives()
        let shown = await makeSUT(excludeSensitives: false).excludeSensitives()

        XCTAssertTrue(excluded)
        XCTAssertFalse(shown)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: some MediaTimelineRepositoryProtocol = MockMediaTimelineRepository(),
        excludeSensitives: Bool = false,
        folderSensitivityChanged: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) -> some MediaTimelineUseCaseProtocol {
        MediaTimelineUseCase(
            repository: repository,
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(excludeSensitives: excludeSensitives),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(folderSensitivityChanged: folderSensitivityChanged))
    }

    private func makeSections() -> [MediaDateSectionEntity] {
        [MediaDateSectionEntity(
            groupId: "2024-07",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 100),
            count: 3)]
    }

    private func makeUpdatesSequence(_ batches: [[NodeEntity]]) -> AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            batches.forEach { continuation.yield($0) }
            continuation.finish()
        }
        .eraseToAnyAsyncSequence()
    }

    private func makeVoidSequence(count: Int) -> AnyAsyncSequence<Void> {
        AsyncStream { continuation in
            for _ in 0..<count { continuation.yield(()) }
            continuation.finish()
        }
        .eraseToAnyAsyncSequence()
    }
}
