@testable import MEGA
import Photos
import Testing

/// Covers the "Upload Only New Photos" preference and the scan-time `creationDate` predicate.
/// Serialized because the preference lives in process-global `UserDefaults`, so parallel cases
/// would race on shared state. A `final class` (not a struct) so teardown can live in `deinit`,
/// which always runs after each test — including when a `#require` throws — guaranteeing the
/// mutated `standardUserDefaults` is restored and never leaks into other tests.
@Suite(.serialized)
final class CameraUploadManagerUploadOnlyNewPhotosTests {
    private let enabledKey = "UploadOnlyNewPhotosEnabled"
    private let cutoffKey = "UploadOnlyNewPhotosCutoff"
    private let savedEnabled: Any?
    private let savedCutoff: Any?

    init() {
        savedEnabled = UserDefaults.standard.object(forKey: enabledKey)
        savedCutoff = UserDefaults.standard.object(forKey: cutoffKey)
        CameraUploadManager.shouldUploadOnlyNewPhotos = false
    }

    deinit {
        UserDefaults.standard.set(savedEnabled, forKey: enabledKey)
        UserDefaults.standard.set(savedCutoff, forKey: cutoffKey)
    }

    private var mediaTypes: [NSNumber] {
        [NSNumber(value: PHAssetMediaType.image.rawValue), NSNumber(value: PHAssetMediaType.video.rawValue)]
    }

    // MARK: - Preference

    @Test func defaultsToOffWithNoCutoff() {
        #expect(CameraUploadManager.shouldUploadOnlyNewPhotos == false)
        #expect(CameraUploadManager.uploadOnlyNewPhotosCutoff == nil)
    }

    @Test func turningOn_persistsCutoffAtAboutNow() throws {
        let before = Date()
        CameraUploadManager.shouldUploadOnlyNewPhotos = true
        let after = Date()

        #expect(CameraUploadManager.shouldUploadOnlyNewPhotos)
        let cutoff = try #require(CameraUploadManager.uploadOnlyNewPhotosCutoff)
        #expect(cutoff >= before)
        #expect(cutoff <= after)
    }

    @Test func reaffirmingOn_doesNotMoveCutoffForward() throws {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true
        let firstCutoff = try #require(CameraUploadManager.uploadOnlyNewPhotosCutoff)

        CameraUploadManager.shouldUploadOnlyNewPhotos = true
        let secondCutoff = try #require(CameraUploadManager.uploadOnlyNewPhotosCutoff)

        #expect(firstCutoff == secondCutoff)
    }

    @Test func turningOff_clearsCutoff() {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true
        #expect(CameraUploadManager.uploadOnlyNewPhotosCutoff != nil)

        CameraUploadManager.shouldUploadOnlyNewPhotos = false
        #expect(CameraUploadManager.shouldUploadOnlyNewPhotos == false)
        #expect(CameraUploadManager.uploadOnlyNewPhotosCutoff == nil)
    }

    // MARK: - Scan fetch options (toggle OFF)

    @Test func scanMediaTypeFetchOptions_whenToggleOff_hasNoCreationDateClause() {
        CameraUploadManager.shouldUploadOnlyNewPhotos = false

        let predicate = PHFetchOptions.mnz_scanFetchOptionsForCameraUpload(withMediaTypes: mediaTypes).predicate
        #expect(predicate != nil)
        #expect(!(predicate is NSCompoundPredicate))
        #expect(predicate?.predicateFormat.contains("creationDate") == false)
    }

    @Test func scanLivePhotoFetchOptions_whenToggleOff_hasNoCreationDateClause() {
        CameraUploadManager.shouldUploadOnlyNewPhotos = false

        let predicate = PHFetchOptions.mnz_scanFetchOptionsForLivePhoto().predicate
        #expect(predicate != nil)
        #expect(predicate?.predicateFormat.contains("creationDate") == false)
    }

    // MARK: - Scan fetch options (toggle ON)

    @Test func scanMediaTypeFetchOptions_whenToggleOn_andsCreationDateClauseOntoMediaTypeClause() throws {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true
        #expect(CameraUploadManager.uploadOnlyNewPhotosCutoff != nil)

        let predicate = try #require(PHFetchOptions.mnz_scanFetchOptionsForCameraUpload(withMediaTypes: mediaTypes).predicate)
        let compound = try #require(predicate as? NSCompoundPredicate)
        #expect(compound.compoundPredicateType == .and)
        #expect(compound.subpredicates.count == 2)

        let formats = compound.subpredicates.compactMap { ($0 as? NSPredicate)?.predicateFormat }
        #expect(formats.contains { $0.contains("mediaType") })
        #expect(formats.contains { $0.contains("creationDate") })
    }

    @Test func scanLivePhotoFetchOptions_whenToggleOn_andsCreationDateClauseOntoLivePhotoClause() throws {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true

        let predicate = try #require(PHFetchOptions.mnz_scanFetchOptionsForLivePhoto().predicate)
        let compound = try #require(predicate as? NSCompoundPredicate)
        #expect(compound.compoundPredicateType == .and)
        #expect(compound.subpredicates.count == 2)

        let formats = compound.subpredicates.compactMap { ($0 as? NSPredicate)?.predicateFormat }
        #expect(formats.contains { $0.contains("mediaSubtype") })
        #expect(formats.contains { $0.contains("creationDate") })
    }

    // MARK: - Lookup fetch options never carry the cutoff

    // Regression guard: `mnz_fetchOptionsForCameraUpload` / `mnz_fetchOptionsForLivePhoto` are used
    // to resolve an existing upload record's asset by local identifier (UploadOperationFactory).
    // They must never get the cutoff, otherwise a pre-cutoff in-flight record would fail asset
    // lookup once the preference is enabled.

    @Test func lookupFetchOptions_whenToggleOn_hasNoCreationDateClause() throws {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true

        let predicate = try #require(PHFetchOptions.mnz_fetchOptionsForCameraUpload().predicate)
        #expect(!predicate.predicateFormat.contains("creationDate"))
    }

    @Test func lookupLivePhotoFetchOptions_whenToggleOn_hasNoCreationDateClause() throws {
        CameraUploadManager.shouldUploadOnlyNewPhotos = true

        // The base live-photo predicate is itself a `mediaType … AND mediaSubtype …` compound,
        // so only assert the cutoff clause is absent — not that it is non-compound.
        let predicate = try #require(PHFetchOptions.mnz_fetchOptionsForLivePhoto().predicate)
        #expect(!predicate.predicateFormat.contains("creationDate"))
    }
}
