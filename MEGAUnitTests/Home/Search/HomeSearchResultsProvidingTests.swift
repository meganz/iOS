@testable import MEGA
import MEGADomain
import MEGADomainMock
import Search
import XCTest

class HomeSearchProvidingTests: XCTestCase {
    func testHomeSearch_whenSuccess_shouldReturnResults() async throws {
        let sut = makeSUT(
            searchFileUseCase: MockSearchFileUseCase(
                nodes: [
                    .init(name: "node 0"),
                    .init(name: "node 1"),
                    .init(name: "node 2"),
                    .init(name: "node 10")
                ]
            ),
            nodeDetailsUseCase: MockNodeDetailUseCase(
                owner: .init(name: "owner"),
                thumbnail: UIImage(systemName: "square.and.arrow.up")
            )
        )

        let expectedResults: [SearchResult] = [
            .init(
                id: .init(stringLiteral: ""),
                title: "node 1",
                description: "owner",
                properties: [],
                thumbnailImageData: { UIImage(named: "square.and.arrow.up")?.pngData() ?? Data() },
                type: .node
            ),
            .init(
                id: .init(stringLiteral: ""),
                title: "node 10",
                description: "owner",
                properties: [],
                thumbnailImageData: { UIImage(named: "square.and.arrow.up")?.pngData() ?? Data() },
                type: .node
            )
        ]

        let searchResults = try await sut.search(
            queryRequest: .init(
                query: "node 1",
                sorting: .automatic,
                mode: .home,
                chips: []
            )
        )

        XCTAssertEqual(searchResults.results.count, 2)

        searchResults.results.enumerated().forEach { index, result in
            XCTAssertEqual(
                result.title,
                expectedResults[index].title,
                "Expect to match title, but failed at index: \(index)"
            )
            XCTAssertEqual(
                result.description,
                expectedResults[index].description,
                "Expect to match description, but failed at index: \(index)"
            )
        }

        let thumbnail = await searchResults.results[0].thumbnailImageData()
        XCTAssertEqual(thumbnail, UIImage(systemName: "square.and.arrow.up")?.pngData())
    }

    func testHomeSearch_whenFailures_shouldReturnNoResults() async throws {
        let sut = makeSUT()

        let searchResults = try await sut.search(
            queryRequest: .init(
                query: "search tests",
                sorting: .automatic,
                mode: .home,
                chips: []
            )
        )

        XCTAssertEqual(searchResults.results.count, 0)
    }

    private func makeSUT(
        searchFileUseCase: MockSearchFileUseCase = .init(),
        nodeDetailsUseCase: MockNodeDetailUseCase = .init(),
        file: StaticString = #filePath,
        line: UInt = #line

    ) -> HomeSearchResultsProviding {
        let sut = HomeSearchResultsProviding(
            searchFileUseCase: searchFileUseCase,
            nodeDetailUseCase: nodeDetailsUseCase
        )

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return sut
    }
}
