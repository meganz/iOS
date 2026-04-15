import Foundation
import Testing
@testable import MediaImport

@Suite("PrepareMediaImportUseCase")
struct PrepareMediaImportUseCaseTests {

    // MARK: - Empty input

    @Test("Returns empty sequence for zero items")
    func emptyInput() async {
        let repo = MockMediaImportRepository()
        let sut = PrepareMediaImportUseCase(itemProviders: [], repository: repo)

        var events: [MediaImportProgressEntity] = []
        for await progress in sut.prepareItems() {
            events.append(progress)
        }

        #expect(events.isEmpty)
    }

    // MARK: - Single item

    @Test("Completes single item successfully")
    func singleItemSuccess() async {
        let expectedURL = URL(fileURLWithPath: "/tmp/photo.heic")
        let repo = MockMediaImportRepository()
        repo.stub(results: [.success(expectedURL)])

        let provider = NSItemProvider()
        let sut = PrepareMediaImportUseCase(itemProviders: [provider], repository: repo)

        var lastProgress: MediaImportProgressEntity?
        for await progress in sut.prepareItems() {
            lastProgress = progress
        }

        #expect(lastProgress?.completedCount == 1)
        #expect(lastProgress?.failedCount == 0)
        #expect(lastProgress?.totalCount == 1)
        #expect(lastProgress?.fractionCompleted == 1.0)
    }

    @Test("Reports failure for single item")
    func singleItemFailure() async {
        let repo = MockMediaImportRepository()
        repo.stub(results: [.failure(NSError(domain: "test", code: 1))])

        let provider = NSItemProvider()
        let sut = PrepareMediaImportUseCase(itemProviders: [provider], repository: repo)

        var lastProgress: MediaImportProgressEntity?
        for await progress in sut.prepareItems() {
            lastProgress = progress
        }

        #expect(lastProgress?.completedCount == 0)
        #expect(lastProgress?.failedCount == 1)
        #expect(lastProgress?.totalCount == 1)
        #expect(lastProgress?.latestError != nil)
    }

    // MARK: - Multiple items

    @Test("Completes multiple items with correct counts")
    func multipleItemsSuccess() async {
        let repo = MockMediaImportRepository()
        repo.stub(results: [
            .success(URL(fileURLWithPath: "/tmp/a.heic")),
            .success(URL(fileURLWithPath: "/tmp/b.heic")),
            .success(URL(fileURLWithPath: "/tmp/c.heic"))
        ])

        let providers = (0..<3).map { _ in NSItemProvider() }
        let sut = PrepareMediaImportUseCase(itemProviders: providers, repository: repo)

        var lastProgress: MediaImportProgressEntity?
        for await progress in sut.prepareItems() {
            lastProgress = progress
        }

        #expect(lastProgress?.completedCount == 3)
        #expect(lastProgress?.failedCount == 0)
        #expect(lastProgress?.totalCount == 3)
    }

    @Test("Mixed success and failure")
    func mixedResults() async {
        let repo = MockMediaImportRepository()
        repo.stub(results: [
            .success(URL(fileURLWithPath: "/tmp/a.heic")),
            .failure(NSError(domain: "test", code: 1)),
            .success(URL(fileURLWithPath: "/tmp/c.heic"))
        ])

        let providers = (0..<3).map { _ in NSItemProvider() }
        let sut = PrepareMediaImportUseCase(itemProviders: providers, repository: repo)

        var lastProgress: MediaImportProgressEntity?
        for await progress in sut.prepareItems() {
            lastProgress = progress
        }

        #expect(lastProgress?.completedCount == 2)
        #expect(lastProgress?.failedCount == 1)
        #expect(lastProgress?.totalCount == 3)
    }

    // MARK: - Progress reporting

    @Test("Reports intermediate progress events")
    func intermediateProgress() async {
        let repo = MockMediaImportRepository()
        repo.stub(results: [.success(URL(fileURLWithPath: "/tmp/a.heic"))])

        let provider = NSItemProvider()
        let sut = PrepareMediaImportUseCase(itemProviders: [provider], repository: repo)

        var progressEvents: [MediaImportProgressEntity] = []
        for await progress in sut.prepareItems() {
            progressEvents.append(progress)
        }

        // Mock emits progress at 0.5 and 1.0, plus completion event
        #expect(progressEvents.count >= 2)
        #expect(progressEvents.last?.completedCount == 1)
    }

    @Test("Progress fraction increases monotonically")
    func monotonicProgress() async {
        let repo = MockMediaImportRepository()
        repo.stub(results: (0..<5).map { i in
            .success(URL(fileURLWithPath: "/tmp/\(i).heic"))
        })

        let providers = (0..<5).map { _ in NSItemProvider() }
        let sut = PrepareMediaImportUseCase(itemProviders: providers, repository: repo)

        var previousFraction = -1.0
        for await progress in sut.prepareItems() {
            #expect(progress.fractionCompleted >= previousFraction)
            previousFraction = progress.fractionCompleted
        }
    }

    // MARK: - Prepared URLs

    @Test("Emits prepared URL for each completed item")
    func preparedURLs() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/b.png")
        ]
        let repo = MockMediaImportRepository()
        repo.stub(results: urls.map { .success($0) })

        let providers = (0..<2).map { _ in NSItemProvider() }
        let sut = PrepareMediaImportUseCase(itemProviders: providers, repository: repo)

        var collectedURLs: [URL] = []
        for await progress in sut.prepareItems() {
            if let url = progress.latestPreparedURL {
                collectedURLs.append(url)
            }
        }

        #expect(Set(collectedURLs) == Set(urls))
    }
}
