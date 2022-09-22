import XCTest
@testable import MEGA

final class EmptyStateViewTests: XCTestCase {
    
    var emptyStateImage: UIImage?
    var emptyStateTitle: String?
    var emptyStateDescription: String?
    
    override func tearDown() {
        emptyStateImage = nil
        emptyStateTitle = nil
        emptyStateDescription = nil
    }
    
    private func validate(emptyStateView: EmptyStateView, image: UIImage, title: String, description: String, isButtonHidden: Bool) throws {
        emptyStateImage = try? XCTUnwrap(emptyStateView.imageView?.image)
        XCTAssertTrue(image == emptyStateImage)
        emptyStateTitle = try? XCTUnwrap(emptyStateView.titleLabel?.text)
        XCTAssertTrue(title == emptyStateTitle)
        emptyStateDescription = try? XCTUnwrap(emptyStateView.descriptionLabel?.text)
        XCTAssertTrue(description == emptyStateDescription)
        XCTAssertTrue(emptyStateView.button?.isHidden ?? false == isButtonHidden)
    }
    
    func testEmptyState_Favourites() throws {
        try? validate(emptyStateView: EmptyStateView.create(for: .favourites),
                      image: Asset.Images.EmptyStates.favouritesEmptyState.image,
                      title: Strings.Localizable.noFavourites, description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Photos() {
        try? validate(emptyStateView: EmptyStateView.create(for: .photos),
                      image: Asset.Images.Home.allPhotosEmptyState.image,
                      title: Strings.Localizable.Home.Images.empty,
                      description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Timeline() {
        try? validate(emptyStateView: EmptyStateView.create(for: .timeline(image: Asset.Images.EmptyStates.cameraEmptyState.image, title: Strings.Localizable.cameraUploadsEnabled, description: "", buttonTitle: nil)),
                      image: Asset.Images.EmptyStates.cameraEmptyState.image,
                      title: Strings.Localizable.cameraUploadsEnabled,
                      description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Documents() {
        try? validate(emptyStateView: EmptyStateView.create(for: .documents),
                      image: Asset.Images.Home.documentsEmptyState.image,
                      title: Strings.Localizable.noDocumentsFound,
                      description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Audio() {
        try? validate(emptyStateView: EmptyStateView.create(for: .audio),
                      image: Asset.Images.Home.audioEmptyState.image,
                      title: Strings.Localizable.noAudioFilesFound,
                      description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Videos() {
        try? validate(emptyStateView: EmptyStateView.create(for: .videos),
                      image: Asset.Images.Home.videoEmptyState.image,
                      title: Strings.Localizable.noVideosFound,
                      description: "",
                      isButtonHidden: true)
    }
    
    func testEmptyState_Backups() {
        let isSearchActive = Bool.random()
        try? validate(emptyStateView: EmptyStateView.create(for: .backups(searchActive: isSearchActive)),
                      image: isSearchActive ? Asset.Images.EmptyStates.searchEmptyState.image : Asset.Images.EmptyStates.folderEmptyState.image,
                      title: isSearchActive ? Strings.Localizable.noResults : Strings.Localizable.Backups.Empty.State.message,
                      description: isSearchActive ? "" : Strings.Localizable.Backups.Empty.State.description,
                      isButtonHidden: true)
    }
}
