import MEGAAppPresentation
import MEGADomain
import SwiftUI
import UIKit

final class PSASwiftUIBackedView: UIView, PSAViewType {

    var viewModel: PSAViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] command in
                self?.executeCommand(command)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }

    private var psaEntity: PSAEntity? {
        didSet { render() }
    }

    private var hostingController: UIHostingController<PSAContentView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    func executeCommand(_ command: PSAViewModel.Command) {
        switch command {
        case .configView(let entity):
            psaEntity = entity
        }
    }

    private func render() {
        guard let entity = psaEntity else { return }

        let hasPositive = (entity.positiveText != nil && entity.positiveLink != nil)

        let root = PSAContentView(
            entity: entity,
            onPrimaryAction: { [weak self] in
                guard let self else { return }
                guard let psaEntity = psaEntity else {
                    MEGALogDebug("PSA Entity was nil")
                    return
                }
                
                viewModel?.dispatch(.dismiss(psaView: self, psaEntity: psaEntity))
                if hasPositive, let link = psaEntity.positiveLink {
                    viewModel?.dispatch(.openPSAURLString(link))
                }
            },
            onSecondaryAction: hasPositive ? { [weak self] in
                guard let self else { return }
                guard let psaEntity = psaEntity else {
                    MEGALogDebug("PSA Entity was nil")
                    return
                }
                viewModel?.dispatch(.dismiss(psaView: self, psaEntity: psaEntity))
            } : nil
        )

        if let hc = hostingController {
            hc.rootView = root
            return
        }

        let hc = UIHostingController(rootView: root)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController = hc

        addSubview(hc.view)
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
