
#import "MEGABaseRequestDelegate.h"

@interface MEGAMoveRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;
- (instancetype)initToMoveToTheRubbishBinWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;

@end
