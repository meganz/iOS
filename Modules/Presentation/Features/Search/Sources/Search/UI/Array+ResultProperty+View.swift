import MEGADesignToken
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
        .sorted()
    }
    
    @ViewBuilder func propertyViewsFor(
        layout: ResultCellLayout,
        placement: PropertyPlacement
    ) -> some View {
        Group {
            ForEach(propertiesFor(mode: layout, placement: placement)) { resultProperty in
                propertyView(for: resultProperty).accessibilityLabel(resultProperty.accessibilityLabel)
            }
        }
    }
    
    @ViewBuilder func propertyView(for property: ResultProperty) -> some View {
        switch property.content {
        case let .icon(image: image, scalable: scalable):
            resultPropertyImage(image: image, scalable: scalable, vibrant: property.vibrancyEnabled)
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
func resultPropertyImage(image: UIImage, scalable: Bool, vibrant: Bool) -> some View {
    // missing dynamic type scaling?
    if scalable {
        Image(uiImage: image)
            .resizable()
            .if(vibrant) { $0.renderingMode(.template).foregroundColor(TokenColors.Support.error.swiftUI) }
            .scaledToFit()
    } else {
        Image(uiImage: image)
    }
}
