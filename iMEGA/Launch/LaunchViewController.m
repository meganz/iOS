#import "LaunchViewController.h"

@interface LaunchViewController ()

@end

@implementation LaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.circularShapeLayer = [CAShapeLayer layer];
    self.circularShapeLayer.bounds = self.logoImageView.bounds;
    CGFloat radiusLogoImageView = self.logoImageView.bounds.size.width/2.0f;
    self.circularShapeLayer.position = CGPointMake(radiusLogoImageView, radiusLogoImageView);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radiusLogoImageView, radiusLogoImageView) radius:(radiusLogoImageView + 4.0f) startAngle:-M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    self.circularShapeLayer.path = [path CGPath];
    self.circularShapeLayer.strokeColor = [[UIColor colorWithWhite:1.0 alpha:0.70] CGColor];
    self.circularShapeLayer.fillColor = [[UIColor clearColor] CGColor];
    self.circularShapeLayer.lineWidth = 2.0f;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
