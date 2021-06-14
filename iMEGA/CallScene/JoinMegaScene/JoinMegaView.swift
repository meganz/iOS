import UIKit
import FlexLayout

class JoinMegaView: UIView {
   
    private let containerView = UIView()
    private let contentsView = UIView()
    private let scrollView = UIScrollView()
    private lazy var createAccountButton: UIButton  = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("createAccount", comment: ""), for: .normal)
        button.mnz_setupPrimary(traitCollection)
        return button
    }()
    
    // MARK: - Internal properties
    private let viewModel: JoinMegaViewModel
    
    init(viewModel: JoinMegaViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        let introducationImage = UIImageView(image: UIImage(named: "il_meeting"))
        
        let title = UILabel()
        title.text = NSLocalizedString("Do More With MEGA", comment: "")
        title.numberOfLines = 0
        title.font = .boldSystemFont(ofSize: 19)
       
        let subtitle = UILabel()
        subtitle.text =  NSLocalizedString("Sign up for a free account and get up to 20GB of storage", comment: "")
        subtitle.numberOfLines = 0
        subtitle.font = .boldSystemFont(ofSize: 11)
        subtitle.textAlignment = .center
        
        contentsView.flex.define { flex in
            let contents = [
                NSLocalizedString("Meeting.CreateAccount.Paragraph.1", comment: ""),
                NSLocalizedString("Meeting.CreateAccount.Paragraph.2", comment: ""),
                NSLocalizedString("Meeting.CreateAccount.Paragraph.3", comment: ""),
                NSLocalizedString("Meeting.CreateAccount.Paragraph.4", comment: "")
            ]
            
            contents.forEach { item in
                flex.addItem().direction(.row).alignItems(.center).marginBottom(16).marginHorizontal(16).define { flex in
                    let dot = UILabel()
                    dot.text = "•"
                    dot.font = .boldSystemFont(ofSize: 30)
                    dot.textAlignment = .center
                    dot.textColor = .mnz_turquoise(for: traitCollection)
                    flex.addItem(dot).width(28)
                    let content = UILabel()
                    content.numberOfLines = 0
                    content.font = .systemFont(ofSize: 12)
                    content.text = item
                    flex.addItem(content).shrink(1).grow(1)
                }
            }
        }
        
        containerView.flex.backgroundColor(.mnz_background()).alignItems(.center).marginTop(28).define { flex in
            // video view
            flex.addItem(introducationImage).marginTop(20).size(CGSize(width: 256, height: 205))
            
            flex.addItem(title).marginTop(28)
            
            flex.addItem(scrollView).grow(1).shrink(1)
            
            // control area
            flex.addItem().width(100%).marginTop(28).paddingHorizontal(43).justifyContent(.center).define({ flex in
                // control panel
                flex.addItem(subtitle).marginBottom(16)
                flex.addItem(createAccountButton).height(50).marginBottom(16).grow(1).shrink(1)
            })
        }
        scrollView.addSubview(contentsView)
        scrollView.contentInset = .init(top: 28, left: 0, bottom: 0, right: 0)
        addSubview(containerView)
        
        createAccountButton.addTarget(self, action: #selector(JoinMegaView.didTapCreateAccountButton), for: .touchUpInside)

    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.pin.all(pin.safeArea)
        containerView.flex.layout()
        contentsView.pin.all()
        contentsView.flex.layout(mode: .adjustHeight)
        
        scrollView.contentSize = contentsView.frame.size
    }
    
    
    // MARK: - Private methods.
    
    @objc func didTapCreateAccountButton() {
        viewModel.dispatch(.didCreateAccountButton)
    }
    

}
