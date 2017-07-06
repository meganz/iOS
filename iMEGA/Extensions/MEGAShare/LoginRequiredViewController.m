
#import "LoginRequiredViewController.h"

@interface LoginRequiredViewController ()

@property (weak, nonatomic) IBOutlet UITextView *loginTextView;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@end

@implementation LoginRequiredViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginTextView.text = AMLocalizedString(@"openMEGAAndSignInToContinue", @"Text shown when you try to use a MEGA extension in iOS and you aren't logged");
    [self.openButton setTitle:AMLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
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
