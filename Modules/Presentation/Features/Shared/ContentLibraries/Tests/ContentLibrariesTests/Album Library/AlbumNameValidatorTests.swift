@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwiftUI
import Testing

@Suite("AlbumNameValidator Tests")
struct AlbumNameValidatorTests {

    @Test
    func testCreate_whenNameIsNil_shouldReturnNil() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = ""
        #expect(sut.create(testName) == nil)
    }
    
    @Test
    func testRename_whenNameIsNil_shouldReturnErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = ""
        let targetError = TextFieldAlertError(title: "", description: "")
        
        #expect(sut.rename(testName) == targetError)
    }
    
    @Test
    func whenNameHasEmptySpaces_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = "       "
        let targetError = TextFieldAlertError(title: "", description: "")
        
        #expect(sut.create(testName) == targetError)
    }
    
    @Test
    func whenNameHasInvalidChars_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = "* adkd"
        let targetError = TextFieldAlertError(title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay), description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterNewName)
        
        #expect(sut.create(testName) == targetError)
    }
    
    @Test
    func whenNameHasReservedAlbumNames_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {[]})
        let testName = Strings.Localizable.CameraUploads.Albums.Favourites.title
        let targetError = TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.albumNameNotAllowed, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        
        #expect(sut.create(testName) == targetError)
    }

    @Test
    func whenNameHasExistingAlbumNames_shouldReturnRightErrorObject() {
        let sut = AlbumNameValidator(existingAlbumNames: {["aaa", "bbb"]})
        let testName = "aaa"
        let targetError = TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.userAlbumExists, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        
        #expect(sut.create(testName) == targetError)
    }
    
    @Test
    func testValidate_whenNameHasValidName_shouldReturnNil() {
        let sut = AlbumNameValidator(existingAlbumNames: {["aaa", "bbb"]})
        let testName = "Hey there this is a new album"
        
        #expect(sut.create(testName) == nil)
    }
    
}
