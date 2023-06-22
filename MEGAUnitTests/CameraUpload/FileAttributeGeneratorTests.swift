@testable import MEGA
import XCTest

final class FileAttributeGeneratorTests: XCTestCase {
    
    let sourceURL = URL(fileURLWithPath: "/path/to/source")
    let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent("thumbnail")
    let previewURL = URL(fileURLWithPath: "/path/to/preview")
    
    func testCreateThumbnail_whenGenerationSucceeds_shouldReturnTrue() async {
        let mockRepresentation = MockThumbnailRepresentation()
        mockRepresentation._cgImage = UIImage(systemName: "folder.fill")?.cgImage
        
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._representation = mockRepresentation
        
        let sut = FileAttributeGenerator(sourceURL: sourceURL, pixelWidth: 100, pixelHeight: 100, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createThumbnail(at: thumbnailURL)
        
        XCTAssertTrue(result, "Thumbnail creation should succeed")
    }
    
    func testCreateThumbnail_whenGenerationFails_shouldReturnFalse() async {
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._error = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        let sut = FileAttributeGenerator(sourceURL: sourceURL, pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createThumbnail(at: thumbnailURL)
        
        XCTAssertFalse(result, "Thumbnail creation should fail")
    }
    
    func testCreatePreview_whenGenerationSucceeds_shouldReturnTrue() async {
        let mockGenerator = MockThumbnailGenerator()
        let sut = FileAttributeGenerator(sourceURL: sourceURL, pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createPreview(at: previewURL)
        
        XCTAssertTrue(result, "Preview creation should succeed")
    }
    
    func testCreatePreview_whenGenerationFails_shouldReturnFalse() async {
        let mockGenerator = MockThumbnailGenerator()
        mockGenerator._error = NSError(domain: "TestErrorDomain", code: 123, userInfo: nil)
        let sut = FileAttributeGenerator(sourceURL: sourceURL, pixelWidth: 1200, pixelHeight: 1200, qlThumbnailGenerator: mockGenerator)
        
        let result = await sut.createPreview(at: previewURL)
        
        XCTAssertFalse(result, "Preview creation should fail")
    }
    
    // MARK: - Mock Classes
    
    class MockThumbnailRepresentation: QLThumbnailRepresentation {
        var _cgImage: CGImage?
        
        override var cgImage: CGImage {
            return _cgImage!
        }
    }
    
    class MockThumbnailGenerator: QLThumbnailGenerator {
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
