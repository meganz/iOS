
#import "MEGASdk+MNZCategory.h"
#import <objc/runtime.h>

#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"

static const void *mnz_accountDetailsKey = &mnz_accountDetailsKey;
static const void *mnz_completedTransfersKey = &mnz_completedTransfersKey;

@implementation MEGASdk (MNZCategory)

#pragma mark - properties

- (MEGAAccountDetails *)mnz_accountDetails {
    return objc_getAssociatedObject(self, mnz_accountDetailsKey);
}

- (void)mnz_setAccountDetails:(MEGAAccountDetails *)newAccountDetails {
    objc_setAssociatedObject(self, &mnz_accountDetailsKey, newAccountDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)completedTransfers {
    NSMutableArray *completedTransfers = objc_getAssociatedObject(self, mnz_completedTransfersKey);
    if (!completedTransfers) {
        completedTransfers = NSMutableArray.new;
        objc_setAssociatedObject(self, &mnz_completedTransfersKey, completedTransfers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return completedTransfers;
}

- (BOOL)mnz_isProAccount {
    return [self.mnz_accountDetails type] > MEGAAccountTypeFree;
}

- (BOOL)mnz_shouldRequestAccountDetails {
    return [objc_getAssociatedObject(self, @selector(mnz_setShouldRequestAccountDetails:)) boolValue];
}

- (void)mnz_setShouldRequestAccountDetails:(BOOL)mnz_shouldRequestAccountDetails {
    objc_setAssociatedObject(self, @selector(mnz_setShouldRequestAccountDetails:), @(mnz_shouldRequestAccountDetails), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
