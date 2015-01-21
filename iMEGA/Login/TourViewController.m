/**
 * @file TourViewController.m
 * @brief View controller that allows select between login or register an account
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "TourViewController.h"
#import "Helper.h"

@interface TourViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *tourScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *tourPageControl;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;

@property (strong, nonatomic) NSArray *images;
@property (strong, nonatomic) NSArray *titles;
@property (strong, nonatomic) NSArray *subtitles;

@end

@implementation TourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"";
    
    self.titles = [NSArray arrayWithObjects:
                   NSLocalizedString(@"megaSpace", nil),
                   NSLocalizedString(@"megaSpeed", nil),
                   NSLocalizedString(@"megaPrivacy", nil),
                   NSLocalizedString(@"megaAccess", nil), nil];
    
    self.subtitles = [NSArray arrayWithObjects:
                      NSLocalizedString(@"megaSpaceText", nil),
                      NSLocalizedString(@"megaSpeedText", nil),
                      NSLocalizedString(@"megaPrivacyText", nil),
                      NSLocalizedString(@"megaAccessText", nil),
                      nil];
    
    
    self.loginButton.layer.cornerRadius = 6;
    self.loginButton.layer.backgroundColor = megaRed.CGColor;
    self.loginButton.layer.masksToBounds = YES;
    [self.loginButton setTitle:NSLocalizedString(@"loginButton", nil) forState:UIControlStateNormal];
    
    self.registerButton.layer.cornerRadius = 6;
    self.registerButton.layer.backgroundColor = megaDarkGray.CGColor;
    self.registerButton.layer.masksToBounds = YES;
    [self.registerButton setTitle:NSLocalizedString(@"registerButton", nil) forState:UIControlStateNormal];
    
    self.titleLabel.textColor = megaRed;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    self.subtitleLabel.textColor = megaDarkGray;
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.images) {
        self.images = [NSArray arrayWithObjects:@"tour0", @"tour1", @"tour2", @"tour3", nil];
        int pos = 0;
        CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
        for (NSString *name in self.images) {
            UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:name]];
            [self.tourScrollView addSubview:img];
            [img setFrame:CGRectMake(width*pos, 0, width, width)];
            pos++;
        }
        
        [self.tourScrollView setContentSize:CGSizeMake(width*4, width)];
    }
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    
    self.titleLabel.text = self.titles[0];
    self.subtitleLabel.text = self.subtitles[0];
    [self.tourPageControl setCurrentPage:0];
    
    self.tourPageControl.numberOfPages = 4;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    self.titleLabel.text = self.titles[page];
    self.subtitleLabel.text = self.subtitles[page];
    [self.tourPageControl setCurrentPage:page];
}

@end
