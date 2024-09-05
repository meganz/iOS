import MEGADomain
import MEGADomainMock
import XCTest

class OfflineUseCaseTests: XCTestCase {
    private let url = URL(string: "file:///data/Containers/Data/Application/3EAE35E8-ABD4-49DE-90C9-C1070C22A6E1/Documents/photos/readme.md")!
    
    func testRelativePathToDocumentsDirectory_shouldReturnExpectedPath() {
        let expectedPath = "photos/readme.md"
        let sut = OfflineUseCase(fileSystemRepository: MockFileSystemRepository(relativePath: expectedPath))
        
        let result = sut.relativePathToDocumentsDirectory(for: url)
        
        XCTAssertEqual(result, expectedPath)
    }
    
    func testRemoveItem_whenSuccess_shouldRemoveTheItem() async throws {
        let fileSystemRepository = MockFileSystemRepository()
        let sut = OfflineUseCase(fileSystemRepository: fileSystemRepository)
        
        try await sut.removeItem(at: url)
        
        XCTAssertEqual(fileSystemRepository.removeFileURLs, [url])
    }
}
