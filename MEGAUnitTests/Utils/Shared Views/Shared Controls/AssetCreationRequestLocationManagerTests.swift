import CoreLocation
@testable import MEGA
import XCTest

final class AssetCreationRequestLocationManagerTests: XCTestCase {
    
    func testRequestWhenInUseAuthorization_whenShouldNotIncludeGPSTags_doesNotRequestAuthorization() {
        let locationManager = MockLocationManager()
        let sut = AssetCreationRequestLocationManager(
            locationManager: locationManager,
            shouldIncludeGPSTags: false
        )
        
        sut.requestWhenInUseAuthorization()
        
        XCTAssertEqual(locationManager.requestWhenInUseAuthorizationCallCount, 0)
    }
    
    func testRequestWhenInUseAuthorization_whenShouldIncludeGPSTags_requestAuthorization() {
        let locationManager = MockLocationManager()
        let sut = AssetCreationRequestLocationManager(
            locationManager: locationManager,
            shouldIncludeGPSTags: true
        )
        
        sut.requestWhenInUseAuthorization()
        
        XCTAssertEqual(locationManager.requestWhenInUseAuthorizationCallCount, 1)
    }
}

private final class MockLocationManager: CLLocationManager {
    private(set) var requestWhenInUseAuthorizationCallCount = 0
    
    override func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCallCount += 1
    }
}
