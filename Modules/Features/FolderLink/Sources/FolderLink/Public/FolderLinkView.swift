import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct FolderLinkView: View {
    public struct Dependency {
        let link: String
        let onClose: @MainActor () -> Void
        
        public init(
            link: String,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.onClose = onClose
        }
    }
    
    let dependency: Dependency
    
    public init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    public var body: some View {
        NavigationStack {
            Text(dependency.link)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Strings.Localizable.folderLink)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dependency.onClose()
                        } label: {
                            Text(Strings.Localizable.close)
                                .font(.body)
                                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        }
                    }
                }
        }
    }
}
