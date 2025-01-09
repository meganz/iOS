import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct VideoListPlaceholderView: View {
    private let isActive: Bool
    
    private let placeholderCount = 30
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init(isActive: Bool) {
        self.isActive = isActive
    }
    
    private var interfaceOrientation: UIInterfaceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .unknown
        }
        return windowScene.interfaceOrientation
    }
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    private var isLandscape: Bool {
        interfaceOrientation.isLandscape || orientation.isLandscape
    }
    
    public var body: some View {
        ScrollView {
            Group {
                if let columns = columns() {
                    LazyVGrid(columns: columns, spacing: 16) {
                        placeholderCells()
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        placeholderCells()
                    }
                }
            }
            .padding()
        }
        .background(TokenColors.Background.page.swiftUI)
        .opacity(isActive ? 1 : 0)
        .animation(.smooth, value: isActive)
        .onRotate { newOrientation in
            orientation = newOrientation
        }
    }
    
    private func columns() -> [GridItem]? {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            Array(repeating: GridItem(.flexible()), count: isLandscape ? 3 : 2)
        } else if horizontalSizeClass == .compact && verticalSizeClass == .compact {
            Array(repeating: GridItem(.flexible()), count: 2)
        } else {
            nil
        }
    }
    
    private func placeholderCells() -> some View {
        ForEach(0..<placeholderCount, id: \.self) { _ in
            VideoListPlaceholderCell()
        }
        .shimmering(active: isActive)
    }
}

struct VideoListPlaceholderCell: View {
    var body: some View {
        HStack {
            Rectangle()
                .frame(width: 142, height: 80)
                .cornerRadius(8, corners: .allCorners)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .frame(width: 152, height: 16)
                    .cornerRadius(10, corners: .allCorners)
                
                Rectangle()
                    .frame(width: 72, height: 16)
                    .cornerRadius(10, corners: .allCorners)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VideoListPlaceholderView(isActive: true)
}
