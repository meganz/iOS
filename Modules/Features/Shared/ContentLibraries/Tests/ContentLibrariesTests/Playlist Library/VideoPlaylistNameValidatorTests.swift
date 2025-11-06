@testable import ContentLibraries
import MEGAL10n
import MEGASwiftUI
import XCTest

final class VideoPlaylistNameValidatorTests: XCTestCase {
    
    // MARK: - validateWhenCreated
    
    @MainActor
    func testCreate_whenNameIsEmpty_shouldReturnNil() {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = ""
        
        assertCreateByCatchingError(on: sut, name: testName, expectedError: .emptyName)
    }
    
    @MainActor
    func testValidateWhenCreated_whenNameHasEmptySpaces_shouldThrowError() {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = "       "
        
        assertCreateByCatchingError(on: sut, name: testName, expectedError: .emptyName)
    }
    
    @MainActor
    func testValidateWhenCreated_whenNameHasInvalidChars_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = "* adkd"
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay),
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterNewName
        )
        
        let result = try sut.validateWhenCreated(with: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenCreated_whenNameHasReservedVideoPlaylistNames_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.videoPlaylistNameNotAllowed,
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
        )
        
        let result = try sut.validateWhenCreated(with: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenCreated_whenNameHasExistingVideoPlaylistNames_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {["aaa", "bbb"]})
        let testName = "aaa"
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.userVideoPlaylistExists,
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
        )
        
        let result = try sut.validateWhenCreated(with: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenCreated_whenNameHasValidName_shouldReturnNil() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {["aaa", "bbb"]})
        let testName = "Hey there this is a new video playlist"
        
        let result = try sut.validateWhenCreated(with: testName)
        
        XCTAssertNil(result)
    }
    
    // MARK: - validateWhenRenamed
    @MainActor
    func testValidateWhenRenamed_whenNameIsEmpty_shouldReturnErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = ""
        
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertEqual(result, TextFieldAlertError(title: "", description: ""), "Expect to have error object with empty title and description")
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameIsEmpty_shouldReturnNil() {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = ""
        
        assertRenameByCatchingError(on: sut, name: testName, expectedError: TextFieldAlertError(title: "", description: ""))
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameHasEmptySpaces_shouldThrowError() {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = "       "
        
        assertRenameByCatchingError(on: sut, name: testName, expectedError: TextFieldAlertError(title: "", description: ""))
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameHasInvalidChars_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = "* adkd"
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay),
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterNewName
        )
        
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameHasReservedVideoPlaylistNames_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {[]})
        let testName = Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.videoPlaylistNameNotAllowed,
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
        )
        
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameHasExistingVideoPlaylistNames_shouldReturnRightErrorObject() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {["aaa", "bbb"]})
        let testName = "aaa"
        let targetError = TextFieldAlertError(
            title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.userVideoPlaylistExists,
            description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
        )
        
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertEqual(result, targetError)
    }
    
    @MainActor
    func testValidateWhenRenamed_whenNameHasValidName_shouldReturnNil() throws {
        let sut = VideoPlaylistNameValidator(existingVideoPlaylistNames: {["aaa", "bbb"]})
        let testName = "Hey there this is a new video playlist"
        
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertNil(result)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func assertCreateByCatchingError(
        on sut: VideoPlaylistNameValidator,
        name testName: String,
        expectedError: VideoPlaylistNameValidator.ValidatorError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            _ = try sut.validateWhenCreated(with: testName)
            XCTFail("Should catch error", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? VideoPlaylistNameValidator.ValidatorError, expectedError, file: file, line: line)
        }
    }
    
    @MainActor
    private func assertRenameByCatchingError(
        on sut: VideoPlaylistNameValidator,
        name testName: String,
        expectedError: TextFieldAlertError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = sut.validateWhenRenamed(into: testName)
        
        XCTAssertEqual(result, expectedError, file: file, line: line)
    }
}
