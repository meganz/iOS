
#import "MEGATransferList+MNZCategory.h"

@implementation MEGATransferList (MNZCategory)

- (NSArray<MEGATransfer *> *)mnz_transfersArrayFromTranferList {
    NSUInteger transferListCount = self.size.unsignedIntegerValue;
    NSMutableArray *transfersMutableArray = [[NSMutableArray alloc] initWithCapacity:transferListCount];
    for (NSUInteger i = 0; i < transferListCount; i++) {
        MEGATransfer *transfer = [self transferAtIndex:i];
        [transfersMutableArray addObject:transfer];
    }
    
    return transfersMutableArray;
}

@end
