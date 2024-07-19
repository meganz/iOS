import SwiftUI

struct InteractionView<Content: View>: UIViewRepresentable {
    
    let contentPreviewProvider: UIContextMenuContentPreviewProvider
    @ViewBuilder let sourcePreview: () -> Content
    let menu: UIMenu
    let didTapPreview: () -> Void
    let didSelect: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let menuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
        
        let hostView = UIHostingController(rootView: sourcePreview())
        hostView.view.translatesAutoresizingMaskIntoConstraints = false
        hostView.view.backgroundColor = .clear
        
        let constraints = [
            hostView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        view.addSubview(hostView.view)
        view.addConstraints(constraints)
        view.addInteraction(menuInteraction)
        context.coordinator.interaction = menuInteraction
        context.coordinator.hosting = hostView
        context.coordinator.addGestureRecognizer()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // updating the view when thumbnail/preview is returned asynchronously
        context.coordinator.hosting?.rootView = sourcePreview()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            contentPreviewProvider: contentPreviewProvider,
            preview: sourcePreview(),
            menu: menu,
            didTapPreview: didTapPreview,
            didSelect: didSelect
        )
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate, UIGestureRecognizerDelegate {
        let contentPreviewProvider: UIContextMenuContentPreviewProvider
        let menu: UIMenu
        let didTapPreview: () -> Void
        let didSelect: () -> Void
        var interaction: UIContextMenuInteraction?
        var hosting: UIHostingController<Content>?
        
        init(
            contentPreviewProvider: @escaping UIContextMenuContentPreviewProvider,
            preview: Content,
            menu: UIMenu,
            didTapPreview: @escaping () -> Void,
            didSelect: @escaping () -> Void
        ) {
            self.contentPreviewProvider = contentPreviewProvider
            self.menu = menu
            self.didTapPreview = didTapPreview
            self.didSelect = didSelect
        }
        
        func addGestureRecognizer() {
            // custom gesture recognizer is added to properly highlight and unhighlight the list cell
            let gr = MEGATapGestureRecognizer(target: self, action: #selector(tapped))
            
            gr.began = { [weak self] in
                self?.hosting?.view.backgroundColor = .systemGray4
            }
            
            gr.end = { [weak self] in
                self?.hosting?.view.backgroundColor = .clear
            }
            
            hosting?.view?.addGestureRecognizer(gr)
        }
        
        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            didSelect()
        }
        
        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configurationForMenuAtLocation location: CGPoint
        ) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: contentPreviewProvider,
                actionProvider: { [weak self] _ in
                    guard let self = self else { return nil }
                    return self.menu
                }
            )
        }
        
        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
            animator: any UIContextMenuInteractionCommitAnimating
        ) {
            animator.addCompletion(self.didTapPreview)
        }
    }
}
