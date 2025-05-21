@testable import MEGA
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwiftUI
import MEGATest
import SwiftUI
import XCTest

final class NodeInfoLocationViewModelTests: XCTestCase {
    
    func testInit_whenLocationIsNil_viewStateEqualEmpty() {
        let (sut, _) = sut(node: .noLocation)
        XCTAssertEqual(
            sut.viewState,
            .empty(icon: MEGAAssets.Image.info, label: Strings.Localizable.CloudDrive.Info.Node.noLocation))
    }
    
    func testInit_whenLocationIsNotNil_viewStateEqualLoading() {
        let (sut, _) = sut(node: .withLocation)
                           
        XCTAssertEqual(sut.viewState, .loading)
    }
    
    @MainActor
    func testOnViewAppear_whenLocationIsNil_viewStateRemainsEmpty() async {
        let (sut, _) = sut(node: .noLocation)
        
        XCTAssertEqual(
            sut.viewState,
            .empty(icon: MEGAAssets.Image.info, label: Strings.Localizable.CloudDrive.Info.Node.noLocation))
        
        await sut.onViewAppear()
        
        XCTAssertEqual(
            sut.viewState,
            .empty(icon: MEGAAssets.Image.info, label: Strings.Localizable.CloudDrive.Info.Node.noLocation))
    }
    
    @MainActor
    func testOnViewAppear_whenLocationIsNotNil_viewStateEqualsLoaded() async throws {
        let node: NodeEntity = .withLocation
        let (sut, location) = sut(
            node: node,
            geoCoderUseCase: MockGeoCoderUseCase(placeMark: .success(.init()))
        )

        XCTAssertEqual(sut.viewState, .loading)
        
        await sut.onViewAppear()
        
        switch sut.viewState {
        case .loaded(let marker):
            XCTAssertEqual(marker.id, node.handle)
            XCTAssertEqual(marker.location.coordinate.latitude, location?.coordinate.latitude)
            XCTAssertEqual(marker.location.coordinate.longitude, location?.coordinate.longitude)
        default:
            XCTFail("Expected a loaded state, not \(sut.viewState)")
        }
    }
        
    private func sut(
        node: NodeEntity,
        geoCoderUseCase: MockGeoCoderUseCase = MockGeoCoderUseCase()
    ) -> (NodeInfoLocationViewModel, CLLocation?) {
        let viewModel = NodeInfoLocationViewModel(
            nodeEntity: node,
            geoCoderUseCase: geoCoderUseCase
        )
        
        return if let latitude = node.latitude, let longitude = node.longitude {
            (viewModel, CLLocation(latitude: latitude, longitude: longitude))
        } else {
            (viewModel, nil)
        }
    }
}

fileprivate extension NodeEntity {
    static var noLocation: NodeEntity {
        .init(handle: 1, latitude: nil, longitude: nil)
    }
    
    static var withLocation: NodeEntity {
        .init(handle: 1, latitude: -36.8462683, longitude: 174.7577764)
    }
}
