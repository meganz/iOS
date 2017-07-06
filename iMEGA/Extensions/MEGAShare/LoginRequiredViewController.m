
#import "LoginRequiredViewController.h"

@interface LoginRequiredViewController ()

@end

@implementation LoginRequiredViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions

- (IBAction)openMegaTouchUpInside:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    self.cancelCompletion();
}

@end
