@testable import MEGA
import XCTest

final class ChatRoomAvatarInitialsGeneratorTest: XCTestCase {

    func testGenerateInitials_oneWordName_initialsShouldHaveOneLetter() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "Banghua")
        XCTAssertEqual(sut, "B")
    }
    
    func testGenerateInitials_oneLetterName_initialsShouldHaveOneLetter() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "B")
        XCTAssertEqual(sut, "B")
    }
    
    func testGenerateInitials_twoWordsName_initialsShouldHaveTwoLetters() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "Banghua Zhao")
        XCTAssertEqual(sut, "BZ")
    }
    
    func testGenerateInitials_firstWordAndSecondLetterName_initialsShouldHaveOneLetterFromWord() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "Banghua Z")
        XCTAssertEqual(sut, "B")
    }
    
    func testGenerateInitials_firstLetterAndSecondWordName_initialsShouldHaveOneLetterFromWord() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "B Zhao")
        XCTAssertEqual(sut, "Z")
    }
    
    func testGenerateInitials_twoLettersName_initialsShouldHaveTwoLetters() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "B Z")
        XCTAssertEqual(sut, "BZ")
    }
    
    func testGenerateInitials_noName_initialsShouldBeDefaultCC() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "")
        XCTAssertEqual(sut, "CC")
    }
    
    func testGenerateInitials_firstAndSecondAndThirdWordsName_initialsShouldHaveTwoLettersFromTwoPrefix() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "Banghua Zhao Neil")
        XCTAssertEqual(sut, "BZ")
    }
    
    func testGenerateInitials_firstWordAndSecondLetterAndThirdWordName_initialsShouldHaveOneLetterFromWordFromTwoPrefix() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "Banghua Z Neil")
        XCTAssertEqual(sut, "B")
    }
    
    func testGenerateInitials_firstLetterAndSecondWordAndThirdWordName_initialsShouldHaveOneLetterFromWordFromTwoPrefix() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "B Zhao Neil")
        XCTAssertEqual(sut, "Z")
    }
    
    func testGenerateInitials_twoLettersAndThirdWordsName_initialsShouldHaveTwoLettersFromTwoPrefix() {
        let sut = ChatRoomAvatarInitialsGenerator.generateInitials(from: "B Z Neil")
        XCTAssertEqual(sut, "BZ")
    }
}
