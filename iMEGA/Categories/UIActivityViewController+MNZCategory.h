#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGAChatMessage;

@interface UIActivityViewController (MNZCategory)

+ (UIActivityViewController *_Nullable)activityViewControllerForChatMessages:(NSArray<MEGAChatMessage *> *)messages sender:(id _Nullable)sender;

+ (UIActivityViewController *)activityViewControllerForNodes:(NSArray *)nodesArray sender:(id _Nullable)sender;

@end

NS_ASSUME_NONNULL_END
