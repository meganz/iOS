
#import <Foundation/Foundation.h>

@interface UITextField (MNZCategory)

@property (nonatomic, copy) BOOL (^shouldReturnCompletion)(UITextField *textField);

@end
