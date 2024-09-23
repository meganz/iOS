import MEGADomain

extension AccountPlanErrorEntity {
    
    public static var random: AccountPlanErrorEntity {
        AccountPlanErrorEntity(
            errorCode: Int.random(in: 1...4),
            errorMessage: ["Error", nil].randomElement() ?? nil
        )
    }
}
