import SwiftUI

struct TextFieldAlertRepresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextFieldAlertViewModel
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<TextFieldAlertRepresenter>) -> UIViewController {
        UIViewController()
    }
    
    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController,
                                context: UIViewControllerRepresentableContext<TextFieldAlertRepresenter>) {
        guard context.coordinator.alertController == nil,
              isPresented else { return }
        
        let alertController = UIAlertController(alert: alert)
        context.coordinator.alertController = alertController
        uiViewController.present(alertController, animated: true) {
            isPresented = false
            context.coordinator.alertController = nil
        }
    }
}

public extension View {
    func alert(isPresented: Binding<Bool>, _ alert: TextFieldAlertViewModel) -> some View {
        background(TextFieldAlertRepresenter(isPresented: isPresented, alert: alert))
    }
}
