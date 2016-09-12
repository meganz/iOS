#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FileLinkMode) {
    FileLinkModeDefault = 0,
    FileLinkModeNodeFromFolderLink
};

@interface FileLinkViewController : UIViewController

@property (nonatomic) FileLinkMode fileLinkMode;
@property (nonatomic, strong) NSString *fileLinkString;
@property (nonatomic, strong) MEGANode *nodeFromFolderLink;

@end
