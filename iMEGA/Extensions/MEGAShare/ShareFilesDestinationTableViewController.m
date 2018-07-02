
#import "ShareFilesDestinationTableViewController.h"

#import "BrowserViewController.h"
#import "NSString+MNZCategory.h"
#import "SendToViewController.h"
#import "ShareAttachment.h"
#import "ShareViewController.h"
#import "UIImageView+MNZCategory.h"

@interface ShareFilesDestinationTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) UINavigationController *navigationController;
@property (weak, nonatomic) ShareViewController *shareViewController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@end

@implementation ShareFilesDestinationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController = (UINavigationController *)self.parentViewController;
    self.shareViewController = (ShareViewController *)self.navigationController.parentViewController;
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = 0;
    
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return [ShareAttachment attachmentsArray].count;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"destinationCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"destinationCell"];
        }
        
        UIImageView *imageView = cell.contentView.subviews.firstObject;
        UILabel *label = cell.contentView.subviews.lastObject;

        if (indexPath.row == 0) {
            imageView.image = [UIImage imageNamed:@"upload"];
            label.text = AMLocalizedString(@"uploadToMega", nil);
        } else if (indexPath.row == 1) {
            imageView.image = [UIImage imageNamed:@"sendMessage"];
            label.text = AMLocalizedString(@"sendToContact", nil);
        }
    } else if (indexPath.section == 1) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"];
        }
        
        ShareAttachment *attachment = [[ShareAttachment attachmentsArray] objectAtIndex:indexPath.row];
        NSString *extension = [attachment.name componentsSeparatedByString:@"."].lastObject;
        UIImageView *imageView = cell.contentView.subviews.firstObject;
        UITextField *textField = cell.contentView.subviews.lastObject;
        [imageView mnz_setImageForExtension:extension];
        textField.text = attachment.name;
        textField.tag = indexPath.row;
        textField.delegate = self;
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = @"";
    
    if (section == 0) {
        sectionTitle = AMLocalizedString(@"selectDestination", nil);
    } else if (section == 1) {
        NSString *format = [ShareAttachment attachmentsArray].count == 1 ? AMLocalizedString(@"oneFile", nil) : AMLocalizedString(@"files", nil);
        sectionTitle = [NSString stringWithFormat:format, [ShareAttachment attachmentsArray].count];
    }
    
    return sectionTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *sectionFooter = @"";
    
    if (section == 1) {
        sectionFooter = AMLocalizedString(@"tapFileToRename", nil);
    }
    
    return sectionFooter;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if (section == 1) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.textAlignment = NSTextAlignmentCenter;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:[NSBundle bundleForClass:BrowserViewController.class]];
            BrowserViewController *browserVC = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
            browserVC.browserAction = BrowserActionShareExtension;
            browserVC.browserViewControllerDelegate = self.shareViewController;
            [self.navigationController setToolbarHidden:NO animated:YES];
            [self.navigationController pushViewController:browserVC animated:YES];
        } else if (indexPath.row == 1) {
            UIStoryboard *chatStoryboard = [UIStoryboard storyboardWithName:@"Chat" bundle:[NSBundle bundleForClass:SendToViewController.class]];
            SendToViewController *sendToViewController = [chatStoryboard instantiateViewControllerWithIdentifier:@"SendToViewControllerID"];
            sendToViewController.sendMode = SendModeShareExtension;
            sendToViewController.sendToViewControllerDelegate = self.shareViewController;
            [self.navigationController pushViewController:sendToViewController animated:YES];
        }
    }
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self.shareViewController dismissWithCompletionHandler:^{
        [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Cancel tapped" code:-1 userInfo:nil]];
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSString *name = textField.text;
    NSString *extension = [name componentsSeparatedByString:@"."].lastObject;

    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    if (extension.mnz_isEmpty) {
        UITextPosition *end = textField.endOfDocument;
        textRange = [textField textRangeFromPosition:beginning toPosition:end];
    } else {
        NSRange filenameRange = [name rangeOfString:@"." options:NSBackwardsSearch];
        UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
        textRange = [textField textRangeFromPosition:beginning toPosition:beforeExtension];
    }
    textField.selectedTextRange = textRange;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [[ShareAttachment attachmentsArray] objectAtIndex:textField.tag].name = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
