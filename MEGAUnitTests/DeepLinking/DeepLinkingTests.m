#import <XCTest/XCTest.h>
#import "MEGAUnitTests-Swift.h"
@interface DeepLinkingTests : XCTestCase

@end

@implementation DeepLinkingTests

- (void)testDeepLinkShouldReturnFileLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/file/paBmgYJQ#sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os"];
    XCTAssertEqual([url mnz_type], URLTypeFileLink);

    NSURL *url1 = [NSURL URLWithString:@"https://testbed.preview.mega.co.nz/file/cNpAEKLS#B7T0WMhV38wOUkEUBRy6eej46wWJo0NKQC2Hz3wW0jc"];
    XCTAssertEqual([url1 mnz_type], URLTypeFileLink);

    NSURL *url2 = [NSURL URLWithString:@"mega://#!paBmgYJQ!sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os"];
    XCTAssertEqual([url2 mnz_type], URLTypeFileLink);

    NSURL *url3 = [NSURL URLWithString:@"https://mega.nz/file/paBmgYJQ?a=sdf&b=123#sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os"];
    XCTAssertEqual([url3 mnz_type], URLTypeFileLink);
}

- (void)testDeepLinkShouldReturnFileRequestLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/filerequest/7W2qzsGbNpU"];
    XCTAssertEqual([url mnz_type], URLTypeFileRequestLink);
}

- (void)testDeepLinkShouldReturnFolderLinkType {
    NSURL *url = [NSURL URLWithString:@"https://testbed.preview.mega.co.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A"];
    XCTAssertEqual([url mnz_type], URLTypeFolderLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A"];
    XCTAssertEqual([url1 mnz_type], URLTypeFolderLink);

    NSURL *url2 = [NSURL URLWithString:@"mega://#F!1dICRLJS!snJiad_4WfCKEK7bgPri3A!0ch3QSwA"];
    XCTAssertEqual([url2 mnz_type], URLTypeFolderLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/folder/1dICRLJS?a=sdf&b=123#snJiad_4WfCKEK7bgPri3A"] mnz_type], URLTypeFolderLink);
}

- (void)testDeepLinkShouldReturnEncryptedLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/#P!AgGaA3GQAEBzfpgzeA4GC-CwSRMY0TpxxG6fXPmuUMcsVr2vDnSQYoS0K50PRR5Uh7HjyI2u56t_Lv_AkVRld5-c_rvBFoaqokLtTOz-ELFYE1BgAlhjKcPe3q8iicg9sUPDNjXYzH4"];
    XCTAssertEqual([url mnz_type], URLTypeEncryptedLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#P!AgGaA3GQAEBzfpgzeA4GC-CwSRMY0TpxxG6fXPmuUMcsVr2vDnSQYoS0K50PRR5Uh7HjyI2u56t_Lv_AkVRld5-c_rvBFoaqokLtTOz-ELFYE1BgAlhjKcPe3q8iicg9sUPDNjXYzH4"] mnz_type], URLTypeEncryptedLink);
}

- (void)testDeepLinkShouldReturnConfirmationLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/confirmQ29uZmlybUNvZGVWMr-2MuOxBAAEFCHyYDarFmhsKzA0MTlAbWVnYS5jby5ueglwZXRlciBsaesszDn6UKiJ"];
    XCTAssertEqual([url mnz_type], URLTypeConfirmationLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/confirm?a=sdf&b=123"] mnz_type], URLTypeConfirmationLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/#confirmQ29uZmlybUNvZGVWMr-2MuOxBAAEFCHyYDarFmhsKzA0MTlAbWVnYS5jby5ueglwZXRlciBsaesszDn6UKiJ"] mnz_type], URLTypeConfirmationLink);

}

- (void)testDeepLinkShouldReturnOpenInLinkType {
    NSURL *url = [NSURL URLWithString:@"file:///"];
    XCTAssertEqual([url mnz_type], URLTypeOpenInLink);
}

- (void)testDeepLinkShouldReturnNewSignUpLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/newsignup"];
    XCTAssertEqual([url mnz_type], URLTypeNewSignUpLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/newsignup?a=sdf&b=123"] mnz_type], URLTypeNewSignUpLink);
    
    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#newsignup"];
    XCTAssertEqual([url1 mnz_type], URLTypeNewSignUpLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#newsignup"] mnz_type], URLTypeNewSignUpLink);
}

- (void)testDeepLinkShouldReturnNewBackupUpLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/backup"];
    XCTAssertEqual([url mnz_type], URLTypeBackupLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/backup?a=sdf&b=123"] mnz_type], URLTypeBackupLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#backup"];
    XCTAssertEqual([url1 mnz_type], URLTypeBackupLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#backup"] mnz_type], URLTypeBackupLink);
}

- (void)testDeepLinkShouldReturnIncomingPendingContactsLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/fm/ipc"];
    XCTAssertEqual([url mnz_type], URLTypeIncomingPendingContactsLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/fm/ipc?a=sdf&b=123"] mnz_type], URLTypeIncomingPendingContactsLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#fm/ipc"];
    XCTAssertEqual([url1 mnz_type], URLTypeIncomingPendingContactsLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#fm/ipc"] mnz_type], URLTypeIncomingPendingContactsLink);
}

- (void)testDeepLinkShouldReturnTypeChangeEmailLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/verify"];
    XCTAssertEqual([url mnz_type], URLTypeChangeEmailLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/verify?a=sdf&b=123"] mnz_type], URLTypeChangeEmailLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#verify"];
    XCTAssertEqual([url1 mnz_type], URLTypeChangeEmailLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#verify"] mnz_type], URLTypeChangeEmailLink);
}

- (void)testDeepLinkShouldReturnTypeCancelAccountLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/cancel"];
    XCTAssertEqual([url mnz_type], URLTypeCancelAccountLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/cancel?a=sdf&b=123"] mnz_type], URLTypeCancelAccountLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#cancel"];
    XCTAssertEqual([url1 mnz_type], URLTypeCancelAccountLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#cancel"] mnz_type], URLTypeCancelAccountLink);
}

- (void)testDeepLinkShouldReturnTypeRecoverLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/recover"];
    XCTAssertEqual([url mnz_type], URLTypeRecoverLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/recover?a=sdf&b=123"] mnz_type], URLTypeRecoverLink);
}

- (void)testDeepLinkShouldReturnTypeContactLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/C!"];
    XCTAssertEqual([url mnz_type], URLTypeContactLink);

    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/C!?a=sdf&b=123"] mnz_type], URLTypeContactLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#C!"];
    XCTAssertEqual([url1 mnz_type], URLTypeContactLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#C!"] mnz_type], URLTypeContactLink);
}

- (void)testDeepLinkShouldReturnTypeOpenChatSectionLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/fm/chat"];
    XCTAssertEqual([url mnz_type], URLTypeOpenChatSectionLink);
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/fm/chat?a=sdf&b=123"] mnz_type], URLTypeOpenChatSectionLink);

    NSURL *url1 = [NSURL URLWithString:@"https://mega.nz/#fm/chat"];
    XCTAssertEqual([url1 mnz_type], URLTypeOpenChatSectionLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#fm/chat"] mnz_type], URLTypeOpenChatSectionLink);
}

- (void)testDeepLinkShouldReturnTypePublicChatLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/chat/X1FRRCaL#a7qjLayRnqR0fFHpov8DrA"];
    XCTAssertEqual([url mnz_type], URLTypePublicChatLink);
        
    NSURL *url1 = [NSURL URLWithString:@"mega://chat/5LpjxQAa#N_fC9cHlBXXWdbfpWQHrRg"];
    XCTAssertEqual([url1 mnz_type], URLTypePublicChatLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/chat/X1FRRCaL?a=sdf&b=123#a7qjLayRnqR0fFHpov8DrA"] mnz_type], URLTypePublicChatLink);
}

- (void)testDeepLinkShouldReturnTypeLoginRequiredLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/loginrequired"];
    XCTAssertEqual([url mnz_type], URLTypeLoginRequiredLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/loginrequired?a=sdf&b=123"] mnz_type], URLTypeLoginRequiredLink);
}

- (void)testDeepLinkShouldReturnTypeHandleLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/#sdfsdsdf"];
    XCTAssertEqual([url mnz_type], URLTypeHandleLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/?a=sdf&b=123#sdfsdsdf"] mnz_type], URLTypeHandleLink);
}

- (void)testDeepLinkShouldReturnTypeAchievementsLinkType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/achievements"];
    XCTAssertEqual([url mnz_type], URLTypeAchievementsLink);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/achievements?a=sdf&b=123"] mnz_type], URLTypeAchievementsLink);
}

- (void)testDeepLinkShouldReturnTypeNewTextFileType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/newText"];
    XCTAssertEqual([url mnz_type], URLTypeNewTextFile);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/newText?a=sdf&b=123"] mnz_type], URLTypeNewTextFile);
}

- (void)testDeepLinkShouldReturnPrivacyPolicyType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/privacy"];
    XCTAssertEqual([url mnz_type], URLTypeDefault);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/privacy?a=sdf&b=123"] mnz_type], URLTypeDefault);
}

- (void)testDeepLinkShouldReturnCookiePolicyType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/cookie"];
    XCTAssertEqual([url mnz_type], URLTypeDefault);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/cookie?a=sdf&b=123"] mnz_type], URLTypeDefault);
}

- (void)testDeepLinkShouldReturnTermsOfServiceType {
    NSURL *url = [NSURL URLWithString:@"https://mega.nz/terms"];
    XCTAssertEqual([url mnz_type], URLTypeDefault);
    
    XCTAssertEqual([[NSURL URLWithString:@"https://mega.nz/terms?a=sdf&b=123"] mnz_type], URLTypeDefault);
}

- (void)testDeepLinkShouldReturnTypeChatPeerOptionsLinkType {
    NSURL *url = [NSURL URLWithString:@"mega://chatPeerOptions#base64UserHandle"];
    XCTAssertEqual([url mnz_type], URLTypeChatPeerOptionsLink);
}

- (void)testDeepLinkShouldReturnTypeUploadFileType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.shortcut.uploadFile"];
    XCTAssertEqual([url mnz_type], URLTypeUploadFile);
}

- (void)testDeepLinkShouldReturnTypeScanDocumentType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.shortcut.scanDocument"];
    XCTAssertEqual([url mnz_type], URLTypeScanDocument);
}

- (void)testDeepLinkShouldReturnTypeStartConversationType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.shortcut.startConversation"];
    XCTAssertEqual([url mnz_type], URLTypeStartConversation);
}

- (void)testDeepLinkShouldReturnTypeTypeAddContactType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.shortcut.addContact"];
    XCTAssertEqual([url mnz_type], URLTypeAddContact);
}

- (void)testDeepLinkShouldReturnTypeTypeShowRecentsType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.quickaccess.recents"];
    XCTAssertEqual([url mnz_type], URLTypeShowRecents);
}

- (void)testDeepLinkShouldReturnTypeShowFavouritesType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.quickaccess.favourites"];
    XCTAssertEqual([url mnz_type], URLTypeShowFavourites);
}

- (void)testDeepLinkShouldReturnTypeShowOfflineType {
    NSURL *url = [NSURL URLWithString:@"mega://widget.quickaccess.offline"];
    XCTAssertEqual([url mnz_type], URLTypeShowOffline);
}

- (void)testDeepLinkShouldReturnType_presentFavouriteNode {
    NSURL *url = [NSURL URLWithString:@"mega://widget.quickaccess.favourites/aaaa"];
    XCTAssertEqual([url mnz_type], URLTypePresentFavouritesNode);
}

- (void)testDeepLinkShouldReturnURLPresentOfflineFileType {
    NSURL *url1 = [NSURL URLWithString:@"mega://widget.quickaccess.offline/aaaa"];
    XCTAssertEqual([url1 mnz_type], URLTypePresentOfflineFile);
}

- (void)testDeepLinkShouldReturnTypeDefault {
    NSURL *url = [NSURL URLWithString:@"https://example.com/data.csv#row=4"];
    XCTAssertEqual([url mnz_type], URLTypeDefault);
}

- (void)testDeepLinkShouldReturnTypeAppSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    XCTAssertEqual([url mnz_type], URLTypeAppSettings);
}


@end
