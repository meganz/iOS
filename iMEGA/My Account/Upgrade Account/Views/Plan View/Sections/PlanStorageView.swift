import SwiftUI
import MEGADomain

struct PlanStorageView: View {
    var plan: AccountPlanEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PlanStorageDetailView(title: UpgradeStrings.Localizable.UpgradeAccountPlan.Plan.Details.storage(plan.storage),
                                  detail: plan.storage)
            PlanStorageDetailView(title: UpgradeStrings.Localizable.UpgradeAccountPlan.Plan.Details.transfer(plan.transfer),
                                  detail: plan.transfer)
        }
    }
}

struct PlanStorageDetailView: View {
    var title: String
    var detail: String
    
    @available(iOS 15, *)
    private var detailAttributedText: AttributedString {
        var attributedString = AttributedString(title)
        attributedString.font = .subheadline
        attributedString.foregroundColor = Color(Colors.UpgradeAccount.secondaryText.color)
        
        guard let rangeOfDetail = attributedString.range(of: detail) else {
            return attributedString
        }
        attributedString[rangeOfDetail].foregroundColor = Color(Colors.UpgradeAccount.primaryText.color)
        return attributedString
    }
    
    var body: some View {
        if #available(iOS 15, *) {
            Text(detailAttributedText)
        } else {
            LabelTextWithAttributedString(title: title, detail: detail)
        }
    }
}

//MARK: - Attributed String for iOS 14 and below
struct LabelTextWithAttributedString: UIViewRepresentable {
    var title: String
    var detail: String

    private var detailAttributedText: NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: title,
            attributes: [.font : UIFont.preferredFont(forTextStyle: .subheadline),
                         .foregroundColor: Colors.UpgradeAccount.secondaryText.color]
        )
        
        let range = NSString(string: title).range(of: detail)
        attributedString.addAttributes(
            [.foregroundColor: Colors.UpgradeAccount.primaryText.color],
            range: range
        )
        return attributedString
    }
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.attributedText = detailAttributedText
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {}
}
