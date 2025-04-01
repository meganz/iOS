import MapKit
import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

public struct LocationInfoMapTile<ID: Hashable>: View {

    public enum ViewState: Equatable {
        case loading
        case loaded(LocationInfoMapMarker<ID>)
        case empty(icon: Image, label: String)
    }
    
    private let viewState: ViewState
    
    public init(viewState: ViewState) {
        self.viewState = viewState
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            switch viewState {
            case .loading:
                loadingContent()
                    .shimmering()
            case .loaded(let locationMarker):
                loadedContent(marker: locationMarker)
            case let .empty(icon, label):
                emptyContent(icon: icon, label: label)
            }
        }
        .animation(.easeIn, value: viewState)
    }
    
    @ViewBuilder
    func loadingContent() -> some View {
        Rectangle()
            .aspectRatio(CGSize(width: 358, height: 182), contentMode: .fit)
            .cornerRadius(8, corners: .allCorners)
        
        HStack {
            Rectangle().hidden()
            Rectangle()
                .cornerRadius(8, corners: .allCorners)
        }.frame(height: 16)
    }
    
    func emptyContent(icon: Image, label: String) -> some View {
        HStack(spacing: 8) {
            icon
            Text(label)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func loadedContent(marker: LocationInfoMapMarker<ID>) -> some View {
        map(marker: marker)
            .aspectRatio(CGSize(width: 358, height: 182), contentMode: .fit)
            .cornerRadius(8, corners: .allCorners)
        Text(marker.locationDescription)
            .font(.caption)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }
    
    @ViewBuilder
    func map(marker: LocationInfoMapMarker<ID>) -> some View {
        let region = MKCoordinateRegion(
            center: marker.location.coordinate,
            span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        if #available(iOS 17.0, *) {
            Map(initialPosition: .region(region),
                bounds: nil,
                interactionModes: [],
                scope: nil) {
                Marker(marker.locationTitle, coordinate: marker.location.coordinate)
            }
        } else {
            Map(coordinateRegion: .constant(region),
                interactionModes: [],
                showsUserLocation: false,
                userTrackingMode: .constant(.none),
                annotationItems: [marker]) { marker in
                MapMarker(coordinate: marker.location.coordinate)
            }
        }
    }
}

#Preview("LocationInfoMapTile - Loaded") {
    VStack {
        LocationInfoMapTile(
            viewState: .loaded(
                LocationInfoMapMarker(
                    id: 1234,
                    location: CLLocation(latitude: -36.8462683, longitude: 174.7577764), // MEGA HQ
                    locationTitle: "MEGA HQ",
                    locationDescription: "Auckland Central, New Zealand"
                )
            )
        )
        
        LocationInfoMapTile(
            viewState: .loaded(
                LocationInfoMapMarker(
                    id: 1234,
                    location: CLLocation(latitude: -36.8462683, longitude: 174.7577764), // MEGA HQ
                    locationTitle: "MEGA HQ",
                    locationDescription: "21, Huawei Centre 120 Albert St Auckland, North Island, New Zealand"
                )
            )
        )
    }
    .padding(.all, 8)
}

#Preview("LocationInfoMapTile - Loading") {
    LocationInfoMapTile<String>(
        viewState: .loading
    )
    .padding(.all, 8)
}

#Preview("LocationInfoMapTile - Empty") {
    LocationInfoMapTile<String>(
        viewState: .empty(
            icon: Image(uiImage: .checkmark),
            label: "No location information")
    )
    .padding(.all, 8)
}
