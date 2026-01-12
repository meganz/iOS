import SwiftUI

extension View {
    @ViewBuilder
    func searchableVisible(
        text: Binding<String>,
        isPresented: Binding<Bool>,
        placement: SearchFieldPlacement = .navigationBarDrawer(displayMode: .always)
    ) -> some View {
        if isPresented.wrappedValue {
            if #available(iOS 17.0, *) {
                self.searchable(
                    text: text,
                    isPresented: isPresented,
                    placement: placement
                )
            } else {
                self
                    .searchable(
                        text: text,
                        placement: placement
                    )
                    .background(
                        SearchControllerObserver(isPresented: isPresented)
                            .frame(width: 0, height: 0)
                    )
                    .onAppear {
                        // Delay to ensure search field is rendered before attempting focus
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                findSearchField(in: window)?.becomeFirstResponder()
                            }
                        }
                    }
            }
        } else {
            self
        }
    }
    
    private func findSearchField(in view: UIView) -> UISearchTextField? {
        if let searchTextField = view as? UISearchTextField {
            return searchTextField
        }
        for subview in view.subviews {
            if let found = findSearchField(in: subview) {
                return found
            }
        }
        return nil
    }
}

private struct SearchControllerObserver: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            if let searchController = vc.parent?.navigationItem.searchController {
                searchController.delegate = context.coordinator
            }
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, UISearchControllerDelegate {
        @Binding var isPresented: Bool
        
        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }
        
        func didDismissSearchController(_ searchController: UISearchController) {
            // Cancel tapped → dismiss search
            isPresented = false
        }
    }
}
