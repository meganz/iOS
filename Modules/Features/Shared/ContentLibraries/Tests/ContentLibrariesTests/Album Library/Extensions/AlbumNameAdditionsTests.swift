import MEGAL10n
import Testing

@Suite("AlbumName+Additions Tests")
struct AlbumNameAdditionsTests {
    static let albumPlaceholder = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
    
    @Test("When there is no albums, then it should return placeholder")
    func noAlbums() {
        #expect([String]().newAlbumName() == AlbumNameAdditionsTests.albumPlaceholder)
    }
    
    @Test("When album names does not contain placeholder, then it should return placeholder")
    func doesNotContainPlaceHolder() {
        #expect(["Test"].newAlbumName() == AlbumNameAdditionsTests.albumPlaceholder)
    }
    
    @Test("When album names contain placeholder, then it should append the number",
          arguments: [
            ([albumPlaceholder], "\(albumPlaceholder) (1)"),
            ([albumPlaceholder, "\(albumPlaceholder) (1)", "\(albumPlaceholder) (2)"], "\(albumPlaceholder) (3)")]
    )
    func containsPlaceholder(albumNames: [String], expected: String) {
        #expect(albumNames.newAlbumName() == expected)
    }
}
