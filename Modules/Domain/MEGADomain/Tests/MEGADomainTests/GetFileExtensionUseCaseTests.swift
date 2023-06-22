import MEGADomain
import UniformTypeIdentifiers
import XCTest

class GetFileExtensionUseCaseTests: XCTestCase {
    let sut = GetFileExtensionUseCase()
    let extensionsKeyedByUTIs = ["public.jpeg": "jpg",
                                 "com.adobe.raw-image": "dng",
                                 "public.heic": "heic",
                                 "public.heif": "heif",
                                 "public.png": "png",
                                 "com.apple.quicktime-movie": "mov",
                                 "public.mpeg-4": "mp4",
                                 "com.compuserve.gif": "gif",
                                 "org.webmproject.webp": "webp"]
    
    func testFileExtension_url_uti_mediaType() throws {
        let url = try XCTUnwrap(URL(string: "file://temp/file.hello"))
        
        for media in MediaTypeEntity.allCases {
            for uti in extensionsKeyedByUTIs.keys {
                XCTAssertEqual(sut.fileExtension(for: media, url: url, uniformTypeIdentifier: uti), "hello")
            }
        }
    }
    
    func testFileExtension_uti_mediaType() throws {
        for media in MediaTypeEntity.allCases {
            for (uti, ext) in extensionsKeyedByUTIs {
                XCTAssertEqual(sut.fileExtension(for: media, url: nil, uniformTypeIdentifier: uti), ext)
            }
        }
    }

    func testFileExtension_mediaType() {
        XCTAssertEqual(sut.fileExtension(for: .image, url: nil, uniformTypeIdentifier: nil), FileExtensionEntity.jpg.rawValue)
        XCTAssertEqual(sut.fileExtension(for: .video, url: nil, uniformTypeIdentifier: nil), FileExtensionEntity.mov.rawValue)
    }
    
    func testFileExtension_url_utType_mediaType() throws {
        
        let url = try XCTUnwrap(URL(string: "file://temp/file.hello"))
        
        for media in MediaTypeEntity.allCases {
            for uti in extensionsKeyedByUTIs.keys {
                XCTAssertEqual(sut.fileExtension(for: media, url: url, uti: UTType(uti)), "hello")
            }
        }
    }
    
    func testFileExtension_utType_mediaType() throws {
        
        for media in MediaTypeEntity.allCases {
            for (uti, ext) in extensionsKeyedByUTIs {
                if let utType = UTType(uti) {
                    XCTAssertEqual(sut.fileExtension(for: media, url: nil, uti: utType), ext)
                }
            }
        }
    }
}
