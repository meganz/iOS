@testable import MEGA
import XCTest

final class FileAttributeGeneratorTests: XCTestCase {
    
    let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent("thumbnail")
    let previewURL = URL(fileURLWithPath: "/path/to/preview")
    
    func testCreateThumbnail_whenGenerationSucceeds_shouldReturnTrue() async {
        let mockRepresentation = MockThumbnailRepresentation()
        mockRepresentation._cgImage = UIImage(systemName: "folder.fill")?.cgImage
        
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._representation = mockRepresentation
        
        let sut = makeSUT(pixelWidth: 100, pixelHeight: 100, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createThumbnail(at: thumbnailURL)
        
        XCTAssertTrue(result, "Thumbnail creation should succeed")
    }
    
    func testCreateThumbnail_whenGenerationFails_shouldReturnFalse() async {
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._error = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        let sut = makeSUT(pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createThumbnail(at: thumbnailURL)
        
        XCTAssertFalse(result, "Thumbnail creation should fail")
    }
    
    func testCreatePreview_whenGenerationSucceeds_shouldReturnTrue() async {
        let mockGenerator = MockThumbnailGenerator()
        let sut = makeSUT(pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createPreview(at: previewURL)
        
        XCTAssertTrue(result, "Preview creation should succeed")
    }
    
    func testCreatePreview_whenGenerationFails_shouldReturnFalse() async {
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._error = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        let sut = makeSUT(pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createPreview(at: previewURL)
        
        XCTAssertFalse(result, "Preview creation should fail")
    }
    
    func testFetchThumbnail_whenGenerationSucceeds_shouldReturnImage() async {
        let mockRepresentation = MockThumbnailRepresentation()
        mockRepresentation._uiImage = UIImage(systemName: "folder.fill")
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._representation = mockRepresentation
        
        let sut = makeSUT(qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.requestThumbnail()
        
        XCTAssertNotNil(result)
    }
    
    func testFetchThumbnail_whenGenerationFails_shouldReturnNil() async {
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._error = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        
        let sut = makeSUT(qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.requestThumbnail()
        
        XCTAssertNil(result)
    }
    
    func testSizeForThumbnail_whenWidthIsGreaterThanHeight_heightShouldBeThumbnailSize() {
        let pixelWidth = 1000
        let pixelHeight = 500
        let sut = makeSUT(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        
        let size = sut.functionToTest_sizeForThumbnail()
        
        let expectedWidth = FileAttributeGenerator.Constants.thumbnailSize * pixelWidth / pixelHeight
        
        XCTAssertEqual(size.width, Double(expectedWidth), "Width should be \(expectedWidth)")
        XCTAssertEqual(size.height, Double(FileAttributeGenerator.Constants.thumbnailSize), "Height should be \(FileAttributeGenerator.Constants.thumbnailSize)")
    }
    
    func testSizeForThumbnail_whenWidthIsGreaterThanHeight_andHeightIsZero_heightAndWidthShouldBeThumbnailSize() {
        let pixelWidth = 1000
        let sut = makeSUT(pixelWidth: pixelWidth)
        
        let size = sut.functionToTest_sizeForThumbnail()
        
        XCTAssertEqual(size.width, Double(FileAttributeGenerator.Constants.thumbnailSize), "Width should be \(FileAttributeGenerator.Constants.thumbnailSize)")
        XCTAssertEqual(size.height, Double(FileAttributeGenerator.Constants.thumbnailSize), "Height should be \(FileAttributeGenerator.Constants.thumbnailSize)")
    }
    
    func testSizeForThumbnail_whenHeightIsGreaterThanWidth_widthShouldBeThumbnailSize() {
        let pixelWidth = 500
        let pixelHeight = 1000
        let sut = makeSUT(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        
        let size = sut.functionToTest_sizeForThumbnail()
        
        let expectedWidth = FileAttributeGenerator.Constants.thumbnailSize * pixelHeight / pixelWidth
        
        XCTAssertEqual(size.height, Double(expectedWidth), "Width should be \(expectedWidth)")
        XCTAssertEqual(size.width, Double(FileAttributeGenerator.Constants.thumbnailSize), "Height should be \(FileAttributeGenerator.Constants.thumbnailSize)")
    }
    
    func testSizeForThumbnail_whenHeightIsGreaterThanWidth_andWidthIsZero_heightAndWidthShouldBeThumbnailSize() {
        let pixelHeight = 1000
        let sut = makeSUT(pixelHeight: pixelHeight)
        
        let size = sut.functionToTest_sizeForThumbnail()
        
        XCTAssertEqual(size.height, Double(FileAttributeGenerator.Constants.thumbnailSize), "Width should be \(FileAttributeGenerator.Constants.thumbnailSize)")
        XCTAssertEqual(size.width, Double(FileAttributeGenerator.Constants.thumbnailSize), "Height should be \(FileAttributeGenerator.Constants.thumbnailSize)")
    }
    
    func testSizeForThumbnail_whenHeightAndWidthAreEqual_heightAndWidthShouldBeThumbnailSize() {
        let pixelWidth = 1000
        let pixelHeight = 1000
        let sut = makeSUT(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        
        let size = sut.functionToTest_sizeForThumbnail()
        
        XCTAssertEqual(size.height, Double(FileAttributeGenerator.Constants.thumbnailSize), "Width should be \(FileAttributeGenerator.Constants.thumbnailSize)")
        XCTAssertEqual(size.width, Double(FileAttributeGenerator.Constants.thumbnailSize), "Height should be \(FileAttributeGenerator.Constants.thumbnailSize)")
    }
    
    func testTileRect_whenWidthIsLessThanHeight_shouldReturnCorrectRect() {
        let width = 200
        let height = 400
        let sut = makeSUT(pixelWidth: width, pixelHeight: height)
        
        let rect = sut.functionToTest_tileRect(width: width, height: height)
        
        XCTAssertEqual(rect.size.width, CGFloat(width), "Width should be \(width)")
        XCTAssertEqual(rect.size.height, CGFloat(width), "Height should be \(width)")
        XCTAssertEqual(rect.origin.x, CGFloat(0), "Origin x should be 0")
        XCTAssertEqual(rect.origin.y, CGFloat((height - width) / 2), "Origin y should be \((height - width) / 2)")
    }

    func testTileRect_whenHeightIsLessThanWidth_shouldReturnCorrectRect() {
        let width = 400
        let height = 200
        let sut = makeSUT(pixelWidth: width, pixelHeight: height)
        
        let rect = sut.functionToTest_tileRect(width: width, height: height)
        
        XCTAssertEqual(rect.size.width, CGFloat(height), "Width should be \(height)")
        XCTAssertEqual(rect.size.height, CGFloat(height), "Height should be \(height)")
        XCTAssertEqual(rect.origin.x, CGFloat((width - height) / 2), "Origin x should be \((width - height) / 2)")
        XCTAssertEqual(rect.origin.y, CGFloat(0), "Origin y should be 0")
    }

    func testTileRect_whenWidthAndHeightAreEqual_shouldReturnCorrectRect() {
        let width = 300
        let height = 300
        let sut = makeSUT(pixelWidth: width, pixelHeight: height)
        
        let rect = sut.functionToTest_tileRect(width: width, height: height)
        
        XCTAssertEqual(rect.size.width, CGFloat(width), "Width should be \(width)")
        XCTAssertEqual(rect.size.height, CGFloat(width), "Height should be \(width)")
        XCTAssertEqual(rect.origin.x, CGFloat(0), "Origin x should be 0")
        XCTAssertEqual(rect.origin.y, CGFloat(0), "Origin y should be 0")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        sourceURL: URL = URL(fileURLWithPath: "/path/to/source"),
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        qlThumbnailGenerator: QLThumbnailGenerator = MockThumbnailGenerator()
    ) -> FileAttributeGenerator {
        FileAttributeGenerator(sourceURL: sourceURL, pixelWidth: pixelWidth, pixelHeight: pixelHeight, qlThumbnailGenerator: qlThumbnailGenerator)
    }
    
    // MARK: - Mock Classes
    
    private final class MockThumbnailRepresentation: QLThumbnailRepresentation, @unchecked Sendable {
        var _cgImage: CGImage?
        var _uiImage: UIImage?
        
        override var cgImage: CGImage {
            return _cgImage!
        }
        
        override var uiImage: UIImage {
            return _uiImage!
        }
    }
    
    private final class MockThumbnailGenerator: QLThumbnailGenerator {
        var _representation: QLThumbnailRepresentation?
        var _error: NSError?
        
        override func generateBestRepresentation(for request: QLThumbnailGenerator.Request) async throws -> QLThumbnailRepresentation {
            if let _error {
                throw _error
            }
            return _representation!
        }
        
        override func saveBestRepresentation(for request: QLThumbnailGenerator.Request, to url: URL, contentType: String?) async throws {
            if let _error {
                throw _error
            }
        }
    }
}

extension QLThumbnailGenerator.Request: @unchecked @retroactive Sendable {}
extension QLThumbnailRepresentation: @unchecked @retroactive Sendable {}
