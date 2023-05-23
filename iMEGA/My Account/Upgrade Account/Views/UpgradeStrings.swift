enum UpgradeStrings {
    enum Localizable {
        enum UpgradeAccountPlan {
            enum Button {
                enum BuyAccountPlan {
                    static func title(_ p1: String) -> String {
                        return "Buy \(p1)"
                    }
                }
                enum Restore {
                    static let title = "Restore"
                }
                enum TermsAndPolicies {
                    static let title = "Terms and policies"
                }
            }
            enum Header {
                enum PlanTermPicker {
                    static let monthly = "Monthly"
                    static let yearly = "Yearly"
                }
                enum Title {
                    static let choosePlan = "Choose the right plan for you"
                    static func currentPlan(_ p1: String) -> String {
                        return "Current plan: \(p1)"
                    }
                    static let featuresOfProPlan = "Features of Pro plans"
                    static let saveYearlyBilling = "Save up to 16% with yearly billing"
                    static let subscriptionDetails = "Subscription details"
                }
            }
            enum Message {
                enum Text {
                    static let featuresOfProPlan = "∙ Password-protected links\n\n∙ Links with expiry dates\n\n∙ Transfer quota sharing\n\n∙ Automatic backups\n\n∙ Rewind up to 90 days on Pro Lite and up to 365 days on Pro I, II, and III (coming soon)\n\n∙ Schedule rubbish bin clearing between 7 days and 10 years"
                    static let subscriptionDetails = "Subscriptions are renewed automatically for successive subscription periods of the same duration and at the same price as  the initial period chosen.\nYou can switch off the automatic renewal of your MEGA Pro subscription no later than 24 hours before your next subscription payment is due via your iTunes account settings page."
                }
            }
        }
    }
}
