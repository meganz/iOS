#import <UIKit/UIKit.h>

@class MEGAPhotoBrowserPickerViewController;

@protocol MEGAPhotoBrowserPickerDelegate

- (void)updateCurrentIndexTo:(NSUInteger)newIndex;

@end

@interface MEGAPhotoBrowserPickerViewController : UIViewController

@property (nonatomic) NSArray<MEGANode *> *mediaNodes;
@property (nonatomic) BOOL isFromSharedItem;
@property (nonatomic, weak) id<MEGAPhotoBrowserPickerDelegate> delegate;
@property (nonatomic) MEGASdk *api;

@end
