import SwiftUI
import UIKit

/// A screen the promotional offer landing dialog must not open over.
@MainActor public protocol PromoDialogBlocking {}

/// Hosts a SwiftUI screen the promo dialog must not open over.
public final class PromoDialogBlockingHostingController<Content: View>: UIHostingController<Content>, PromoDialogBlocking {}
