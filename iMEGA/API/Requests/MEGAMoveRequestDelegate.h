
#import "MEGABaseRequestDelegate.h"

@interface MEGAMoveRequestDelegate : MEGABaseRequestDelegate

@property (nonatomic) BOOL restore;

- (instancetype)initWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;
- (nonnull instancetype)initToMoveToTheRubbishBinWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;

@end
