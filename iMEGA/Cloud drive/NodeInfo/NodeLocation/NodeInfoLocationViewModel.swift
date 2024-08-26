import CoreLocation
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

final class NodeInfoLocationViewModel: ObservableObject {
    
    typealias ViewState = LocationInfoMapTile<HandleEntity>.ViewState
    @Published private(set) var viewState: ViewState
    
    private let nodeEntity: NodeEntity
    private let geoCoderUseCase: any GeoCoderUseCaseProtocol
    
    init(nodeEntity: NodeEntity, geoCoderUseCase: some GeoCoderUseCaseProtocol) {
        self.nodeEntity = nodeEntity
        self.geoCoderUseCase = geoCoderUseCase
        viewState = nodeEntity.location != nil ? .loading : Self.emptyState()
    }
    
    @MainActor
    func onViewAppear() async {
        
        guard viewState == .loading else {
            return
        }
        
        do {
            try await loadGeolocationMeta()
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadGeolocationMeta cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] loadGeolocationMeta error: \(error)")
            viewState = Self.emptyState()
        }
    }
    
    @MainActor
    private func loadGeolocationMeta() async throws {
        guard let location = nodeEntity.location else {
            throw GeoCoderErrorEntity.noCoordinatesProvided
        }
        
        let placeMark = try await geoCoderUseCase.placeMark(for: nodeEntity)
        
        try Task.checkCancellation()
        
        viewState = .loaded(.init(id: nodeEntity.handle,
                                  location: location,
                                  locationTitle: placeMark.locationTitle,
                                  locationDescription: placeMark.locationDescription))
    }
    
    private static func emptyState() -> ViewState {
        .empty(icon: Image(uiImage: .info), 
               label: Strings.Localizable.CloudDrive.Info.Node.noLocation)
    }
}

private extension NodeEntity {
    var location: CLLocation? {
        if let latitude, let longitude {
            .init(latitude: latitude, longitude: longitude)
        } else {
            nil
        }
    }
}

private extension PlaceMarkEntity {
    
    var locationTitle: String {
        areasOfInterest?.first ?? ""
    }
    
    var locationDescription: String {
        [subLocality, locality, country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
