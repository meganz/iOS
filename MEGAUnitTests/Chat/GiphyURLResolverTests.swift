@testable import MEGA
import XCTest

final class GiphyURLResolverTests: XCTestCase {
    func testWebURL_giphyShorthand_rewritesToMEGAProxy() {
        let url = GiphyURLResolver.webURL(from: "giphy://media/abc123/giphy.webp")

        XCTAssertEqual(url?.absoluteString, "https://giphy.mega.nz/media/abc123/giphy.webp")
    }

    func testWebURL_absoluteProxyURL_isKept() {
        let source = "https://giphy.mega.nz/media/abc123/giphy.webp"

        XCTAssertEqual(GiphyURLResolver.webURL(from: source)?.absoluteString, source)
    }

    func testWebURL_arbitraryHTTPHost_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "http://203.0.113.7/webp.gif"))
    }

    func testWebURL_arbitraryHTTPSHost_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "https://attacker.example/giphy.webp"))
    }

    func testWebURL_shorthandNotAtStart_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "https://attacker.example/?u=giphy://media/abc/giphy.webp"))
    }

    func testWebURL_lookalikeProxyHost_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "https://giphy.mega.nz.attacker.example/giphy.webp"))
        XCTAssertNil(GiphyURLResolver.webURL(from: "https://giphy.mega.nz@attacker.example/giphy.webp"))
    }

    func testWebURL_plainHTTPProxy_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "http://giphy.mega.nz/media/abc/giphy.webp"))
    }

    func testWebURL_uppercaseShorthand_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: "GIPHY://media/abc/giphy.webp"))
    }

    func testWebURL_shorthandWithUserInfo_staysOnProxyHost() {
        let url = GiphyURLResolver.webURL(from: "giphy://attacker.example@/media/abc/giphy.webp")

        XCTAssertEqual(url?.host, "giphy.mega.nz")
    }

    func testWebURL_nilOrEmpty_isRejected() {
        XCTAssertNil(GiphyURLResolver.webURL(from: nil))
        XCTAssertNil(GiphyURLResolver.webURL(from: ""))
    }
}
