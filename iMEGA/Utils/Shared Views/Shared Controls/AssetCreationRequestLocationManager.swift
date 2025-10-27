@preconcurrency import CoreLocation

protocol AssetCreationRequestLocationManagerProtocol: Sendable {
    func requestWhenInUseAuthorization()
    
    /// This method can only be called from inside of -[PHPhotoLibrary performChanges:completionHandler:] or -[PHPhotoLibrary performChangesAndWait:error:]
    /// - Parameter assetCreationRequest: assetCreationRequest object
    func registerLocationMetaData(to assetCreationRequest: PHAssetCreationRequest)
}

final class AssetCreationRequestLocationManager: AssetCreationRequestLocationManagerProtocol {
    private let locationManager: CLLocationManager
    private let shouldIncludeGPSTags: Bool
    
    init(
        locationManager: CLLocationManager = CLLocationManager(),
        shouldIncludeGPSTags: Bool = CameraUploadManager.shouldIncludeGPSTags
    ) {
        self.locationManager = locationManager
        self.shouldIncludeGPSTags = shouldIncludeGPSTags
    }
    
    func requestWhenInUseAuthorization() {
        if shouldIncludeGPSTags {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func registerLocationMetaData(to assetCreationRequest: PHAssetCreationRequest) {
        if CLLocationManager.locationServicesEnabled() && shouldIncludeGPSTags {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        if let location = locationManager.location, shouldIncludeGPSTags {
            assetCreationRequest.location = location
        }
    }
}

@objc final class AssetCreationRequestLocationManagerOCWrapper: NSObject, AssetCreationRequestLocationManagerProtocol {
    private let adaptee = AssetCreationRequestLocationManager()
    
    @objc func requestWhenInUseAuthorization() {
        adaptee.requestWhenInUseAuthorization()
    }
    
    @objc func registerLocationMetaData(to assetCreationRequest: PHAssetCreationRequest) {
        adaptee.registerLocationMetaData(to: assetCreationRequest)
    }
}
