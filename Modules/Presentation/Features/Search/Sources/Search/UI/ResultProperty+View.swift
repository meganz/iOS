import SwiftUI

extension Array where Element == ResultProperty {
    
    func propertiesFor(
        mode: ResultCellLayout,
        placement: PropertyPlacement
    ) -> [ResultProperty] {
        filter { resultProperty in
            // here we check, for a given display mode, where given property wants to be placed
            // and if it matches the filtered for value, we return it
            resultProperty.placement(mode) == placement
        }
    }
    
    @ViewBuilder func propertyViewsFor(
        mode: ResultCellLayout,
        placement: PropertyPlacement
    ) -> some View {
        Group {
            ForEach(propertiesFor(mode: mode, placement: placement)) { resultProperty in
                propertyView(for: resultProperty.content)
            }
        }
    }
    
    @ViewBuilder func propertyView(for content: ResultProperty.Content) -> some View {
        switch content {
        case let .icon(image: image, scalable: scalable):
            resultPropertyImage(image: image, scalable: scalable)
                .frame(width: 12, height: 12)
        case .text(let text):
            Text(text)
        case .spacer:
            Spacer()
        }
    }
    
}

// extract as we need to reuse it for special styling case
@ViewBuilder
func resultPropertyImage(image: UIImage, scalable: Bool) -> some View {
    // missing dynamic type scaling?
    if scalable {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    } else {
        Image(uiImage: image)
    }
}
