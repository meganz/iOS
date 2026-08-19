import MEGADomain
import Testing

@Suite("PlanEntity - external purchase path")
struct PlanEntityExternalPurchasePlanTests {

    @Test("Each plan maps to the website path that sells it", arguments: [
        (AccountTypeEntity.proI, "propay_1"),
        (.proII, "propay_2"),
        (.proIII, "propay_3"),
        (.lite, "propay_4"),
        (.proFlexi, "propay_101"),
        (.business, "registerb")
    ])
    func externalPurchasePath_forEachPlan_isTheSellingPath(type: AccountTypeEntity, expected: String) {
        #expect(PlanEntity(type: type).externalPurchasePath == expected)
    }

    @Test("A plan with no dedicated page falls back to the plans page", arguments: [
        AccountTypeEntity.free,
        .starter,
        .basic,
        .essential
    ])
    func externalPurchasePath_withoutADedicatedPage_isThePlansPage(type: AccountTypeEntity) {
        #expect(PlanEntity(type: type).externalPurchasePath == "pro")
    }
}
