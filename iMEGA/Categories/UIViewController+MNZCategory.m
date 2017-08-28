
#import "UIViewController+MNZCategory.h"

@implementation UIViewController (MNZCategory)

- (void)mnz_customBackBarButtonItem {
    UIBarButtonItem *backBarButtonItem = [self mnz_prepareCustomBackBarButtonItem];
    self.navigationItem.leftBarButtonItems = @[backBarButtonItem];
}

- (UIBarButtonItem *)mnz_prepareCustomBackBarButtonItem {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mnz_popViewController)];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backArrow"]];
    imageView.frame = CGRectMake(0, 0, 22, 22);
    [imageView addGestureRecognizer:singleTap];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    return backBarButtonItem;
}

- (void)mnz_popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
