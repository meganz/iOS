import CoreServices
import MEGADomain
import MEGAPreference
import Photos
import UIKit
import UniformTypeIdentifiers

final class UploadImagePickerViewController: UIImagePickerController {

    private var assetCreationRequestLocationManager: AssetCreationRequestLocationManager?
    var completion: ((Result<String, ImagePickingError>) -> Void)?
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    private var isSaveMediaCapturedToGalleryEnabled: Bool
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .currentContext
        videoQuality = .typeHigh
        delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initializeAndRequestCameraLocationPermission()
    }
    
    private func initializeAndRequestCameraLocationPermission() {
        if assetCreationRequestLocationManager == nil {
            assetCreationRequestLocationManager = AssetCreationRequestLocationManager()
        }
        assetCreationRequestLocationManager?.requestWhenInUseAuthorization()
    }

    // MARK: - Public

    func prepare(
        withSourceType sourceType: SourceType,
        completion: @escaping (Result<String, ImagePickingError>) -> Void
    ) throws {
        try createTemporaryDirectory()
        try isSourceTypeAvailable(sourceType)

        self.completion = completion

        if let avaialbeMediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType) {
            mediaTypes = avaialbeMediaTypes
        }
    }

    // MARK: - FileSystem

    private func createTemporaryDirectory() throws {
        do {
            try FileManager.default.createDirectory(
                atPath: NSTemporaryDirectory(),
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw ImagePickingError.failedCreateTemporaryData
        }
    }
    
    private func isSourceTypeAvailable(_ sourceType: SourceType) throws {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            throw ImagePickingError.sourceTypeIsNotAvailable
        }
        self.sourceType = sourceType
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension UploadImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let mediaType = info[InfoKey.mediaType] as? String else { return }

        if mediaType == UTType.image.identifier {
            processImageType(with: info[.originalImage] as! UIImage)
            return
        }

        if mediaType == UTType.movie.identifier {
            processMovieType(with: info[.mediaURL] as! URL)
            return
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Post Process Medias

    private func processImageType(with image: UIImage) {
        let imageName = NSDate().mnz_formattedDefaultNameForMedia() + ".jpg"
        guard let imagePath = FileManager.default.uploadsDirectory()?.append(pathComponent: imageName),
            let imageAsData = image.jpegData(compressionQuality: 1) as NSData? else {
            completion?(.failure(.failedCreateTemporaryData))
            return
        }
        imageAsData.write(toFile: imagePath, atomically: true)

        // MARK: - Write some defaults
        
        if !$isSaveMediaCapturedToGalleryEnabled.existed {
            isSaveMediaCapturedToGalleryEnabled = true
        }

        if isSaveMediaCapturedToGalleryEnabled {
            createAsset(fromFilePath: imagePath, forAssetType: .photo)
        } else {
            completion?(.success(relativeLocalPath(imagePath)))
        }
    }

    private func relativeLocalPath(_ filePath: String) -> String {
        (filePath as NSString).mnz_relativeLocalPath()
    }

    private func processMovieType(with videoURL: URL) {
        do {
            let videoAttributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
            guard let modificationDate = videoAttributes[FileAttributeKey.modificationDate] as? NSDate else {
                completion?(.failure(.failedCreateTemporaryData))
                return
            }

            let videoName = modificationDate.mnz_formattedDefaultNameForMedia().appending(".mov")
            guard let localFilePath = FileManager.default.uploadsDirectory()?.append(pathComponent: videoName) else {
                completion?(.failure(.failedCreateTemporaryData))
                return
            }

            try FileManager.default.moveItem(atPath: videoURL.path, toPath: localFilePath)

            if !$isSaveMediaCapturedToGalleryEnabled.existed {
                isSaveMediaCapturedToGalleryEnabled = true
            }

            if isSaveMediaCapturedToGalleryEnabled {
                createAsset(fromFilePath: localFilePath, forAssetType: .video)
            } else {
                completion?(.success(relativeLocalPath(localFilePath)))
            }

        } catch {
            completion?(.failure(.sourceTypeIsNotAvailable))
        }
    }

    private func createAsset(fromFilePath filePath: String, forAssetType assetType: PHAssetResourceType) {

        func relativeLocalPath(_ filePath: String) -> String {
            (filePath as NSString).mnz_relativeLocalPath()
        }

        let assetURL = URL(fileURLWithPath: filePath)

        PHPhotoLibrary.shared().performChanges({ [weak self] in
            guard let self else { return }
            let assetCreationRequest = PHAssetCreationRequest.forAsset()
            assetCreationRequest.addResource(with: assetType, fileURL: assetURL, options: nil)
            assetCreationRequestLocationManager?.registerLocationMetaData(to: assetCreationRequest)
        }, completionHandler: { [completion] (success, _) in
            guard success else {
                completion?(.success(relativeLocalPath(filePath)))
                return
            }

            switch assetType {
            case .photo, .video: completion?(.success(relativeLocalPath(filePath)))
            default:
                completion?(.failure(.unsupportedFileType))
            }
        })
    }
}

enum ImagePickingPurpose {
    case uploading
}

enum ImagePickingError: Error {
    case failedCreateTemporaryData
    case sourceTypeIsNotAvailable
    case unsupportedFileType
}
