//
//  NXSPAuthViewController.m
//  SharepointOnlineSDK
//
//  Created by nextlabs on 22/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXSPAuthViewController.h"
#import "NXLKeyChain.h"

#define ViewWidth 800
#define ViewHeight 600
#define TextFieldWidth 300
#define TextFieldHeight 30
#define TextFieldleft 250
#define TextFieldGapHeight 30
#define TipHeight 15
#define TipGapHeight 10
#define GapHeight 15


@interface NXSPAuthViewController () <NSWindowDelegate, NXSharepointOnlineDelegete>


@property void(^completionHandler)(NXSharePointManager *, NXSharePointOnlineUser *, NSError *);
@property NSString *keychain;
@property NXSharepointOnlineAuthentication *auth;
@property NXSharePointManager *spManager;
@property NSProgressIndicator *indicator;
@property NSTextField *spSiteText;
@property NSTextField *spUsernameText;
@property NSSecureTextField *spPasswordText;
@property NSTextField *siteTip;
@property NSTextField *usernameTip;
@property NSTextField *passwordTip;
@property NSButton *confirmButton;
@end

@implementation NXSPAuthViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (void)loadView{
    NSView *view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, ViewWidth, ViewHeight)];
    self.view = view;
    [self.view setWantsLayer:true];
    if (self.view.layer != nil) {
        CGColorRef colorRef = CGColorCreateGenericRGB(57.0/255.0, 150.0/255.0, 73.0/255.0, 1.0);
        [self.view.layer setBackgroundColor:colorRef];
        CGColorRelease(colorRef);
    }
}


- (void)viewWillAppear{
    [super viewWillAppear];
    self.title = NSLocalizedString(@"SHAREPOINT_ONLINE_AUTH_TITILE", @"");
    
    self.indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, 30, 30)];
    [self.indicator setFrameOrigin:NSMakePoint((NSWidth(self.view.frame) - NSWidth(self.indicator.frame))/2, (NSHeight(self.view.frame) - NSHeight(self.indicator.frame))/2)];
    self.indicator.style = NSProgressIndicatorSpinningStyle;
    [self.indicator setHidden: YES];
    [self.view addSubview:self.indicator];
    
    CGFloat startY = ViewHeight - TextFieldGapHeight;
    self.siteTip = [[NSTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TipHeight)];
    self.siteTip.placeholderString = NSLocalizedString(@"SHAREPOINT_ONLINE_AUTH_URL", @"");
    self.siteTip.drawsBackground = false;
    [self.siteTip setEditable:false];
    self.siteTip.wantsLayer = true;
    CGColorRef siteTipColorRef = CGColorCreateGenericRGB(57.0/255.0, 150.0/255.0, 73.0/255.0, 1.0);
    [self.siteTip.layer setBackgroundColor:siteTipColorRef];
    CGColorRelease(siteTipColorRef);
    [self.siteTip setBordered:false];
    startY -= TextFieldHeight + TipGapHeight;
    self.spSiteText = [[NSTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TextFieldHeight)];
    [self.spSiteText setBezelStyle:NSTextFieldRoundedBezel];
    
    startY -= TextFieldHeight + GapHeight;
    self.usernameTip = [[NSTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TipHeight)];
    self.usernameTip.placeholderString = NSLocalizedString(@"SHAREPOINT_ONLINE_AUTH_USERNAME", @"");
    self.usernameTip.drawsBackground = false;
    [self.usernameTip setEditable:false];
    self.usernameTip.wantsLayer = true;
    [self.usernameTip setBordered:false];
    CGColorRef usernameTipColorRef = CGColorCreateGenericRGB(57.0/255.0, 150.0/255.0, 73.0/255.0, 1.0);
    [self.usernameTip.layer setBackgroundColor:usernameTipColorRef];
    CGColorRelease(usernameTipColorRef);
    startY -= TextFieldHeight + TipGapHeight;
    self.spUsernameText = [[NSTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TextFieldHeight)];
    [self.spUsernameText setBezelStyle:NSTextFieldRoundedBezel];
    
    startY -= TextFieldHeight + GapHeight;
    self.passwordTip = [[NSTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TipHeight)];
    self.passwordTip.placeholderString = NSLocalizedString(@"SHAREPOINT_ONLINE_AUTH_PASSWORD", @"");
    self.passwordTip.drawsBackground = false;
    [self.passwordTip setEditable:false];
    self.passwordTip.wantsLayer = true;
    [self.passwordTip setBordered:false];
    CGColorRef passwordTipColorRef = CGColorCreateGenericRGB(57.0/255.0, 150.0/255.0, 73.0/255.0, 1.0);
    [self.passwordTip.layer setBackgroundColor:passwordTipColorRef];
    CGColorRelease(passwordTipColorRef);
    startY -= TextFieldHeight + TipGapHeight;
    self.spPasswordText = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(TextFieldleft, startY, TextFieldWidth, TextFieldHeight)];
    [self.spPasswordText setBezelStyle:NSTextFieldRoundedBezel];
    
    startY -= TextFieldHeight + GapHeight;
    self.confirmButton = [[NSButton alloc] initWithFrame:NSMakeRect(TextFieldleft+TextFieldWidth / 3, startY, TextFieldWidth / 3, TextFieldHeight)];
    [self.confirmButton setButtonType:NSButtonTypePushOnPushOff];
    [self.confirmButton setBezelStyle:NSRoundedBezelStyle];
    [self.confirmButton setTitle:NSLocalizedString(@"SHAREPOINT_ONLINE_AUTH_OK", @"")];
    [self.confirmButton setAction:@selector(okClicked:)];
    [self.confirmButton setKeyEquivalent:@"\r"];
    
    self.spSiteText.stringValue = @"https://nextlabsdev.sharepoint.com/ProjectNova".localizedLowercaseString;
    self.spUsernameText.stringValue = @"mxu@nextlabsdev.onmicrosoft.com".localizedLowercaseString;
    self.spPasswordText.stringValue = @"123blue!".localizedLowercaseString;
    
    [self.view addSubview:self.spSiteText];
    [self.view addSubview:self.spUsernameText];
    [self.view addSubview:self.spPasswordText];
    [self.view addSubview:self.siteTip];
    [self.view addSubview:self.usernameTip];
    [self.view addSubview:self.passwordTip];
    [self.view addSubview:self.confirmButton];
    
    self.view.window.delegate = self;
}

- (BOOL)windowShouldClose:(id)sender{
    NSError *error = [[NSError alloc] initWithDomain:@"user canceled authorization" code:10001 userInfo:nil];
    if (self.completionHandler) {
        self.completionHandler(nil, nil, error);
    }
    return true;
}
- (IBAction)okClicked:(id)sender {
    [self.spSiteText setEditable:false];
    [self.spUsernameText setEditable:false];
    [self.spPasswordText setEditable:false];
    [self.indicator setHidden:false];
    [self.indicator startAnimation:nil];
    [self.confirmButton setEnabled:false];
    NSString *site = self.spSiteText.stringValue;
    if (false == [site hasSuffix:@"/"]) {
        site = [site stringByAppendingString:@"/"];
    }
    self.auth = [[NXSharepointOnlineAuthentication alloc] initwithUsernamePasswordSite:self.spUsernameText.stringValue password:self.spPasswordText.stringValue site:site];
    self.auth.delegate = self;
    [self.auth login];
}

-(id)init:(NSString *)keychain completion:(void (^)(NXSharePointManager *, NXSharePointOnlineUser *, NSError *))handler{
    if ((self = [super initWithNibName:@"NXSPAuthViewController" bundle:nil]) != nil) {
        self.completionHandler = [handler copy];
        self.keychain = [keychain copy];
    }
    return self;
}
+(NXSharePointManager *)authFromKeychain:(NSString *)keychain{
    NXSharePointOnlineUser *user = [NXLKeyChain load:keychain];
    if (!user) {
        return nil;
    }
    NSDictionary *fedAuthCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                   user.siteurl, NSHTTPCookieOriginURL,
                                   @"FedAuth", NSHTTPCookieName,
                                   @"/", NSHTTPCookiePath,
                                   user.fedauthInfo, NSHTTPCookieValue,
                                   nil];
    
    NSDictionary *rtFaCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                user.siteurl, NSHTTPCookieOriginURL,
                                @"rtFa", NSHTTPCookieName,
                                @"/", NSHTTPCookiePath,
                                user.rtfaInfo, NSHTTPCookieValue,
                                nil];
    
    
    NSHTTPCookie *fedAuthCookieObj = [NSHTTPCookie cookieWithProperties:fedAuthCookie];
    NSHTTPCookie *rtFaCookieObj = [NSHTTPCookie cookieWithProperties:rtFaCookie];
    
    NSArray *cookiesArray = @[fedAuthCookieObj, rtFaCookieObj];
    NXSharePointManager *sp = [[NXSharePointManager alloc] initWithURL:user.siteurl cookies:cookiesArray Type:kSPMgrSharePointOnline];
    return sp;
}
+(void)removeFromKeyChain:(NSString *)keychain {
    [NXLKeyChain delete:keychain];
}
+(void)saveAuthToKeyChain:(NSString *)keychain url:(NSString *)url fedAuth:(NSString *)fedAuth rtfa:(NSString *)rtfa {
    NXSharePointOnlineUser *user = [[NXSharePointOnlineUser alloc] init];
    user.siteurl = url;
    user.fedauthInfo = fedAuth;
    user.rtfaInfo = rtfa;
    [NXLKeyChain save:keychain data:user];
}
//pragma mark: NXSharepointOnlineDelegete
-(void)Authentication:(NXSharepointOnlineAuthentication *)auth didAuthenticateSuccess:(NXSharePointOnlineUser *)user{
    [self.confirmButton setEnabled:true];
    [self.spSiteText setEditable:true];
    [self.spUsernameText setEditable:true];
    [self.spPasswordText setEditable:true];
    [self.indicator stopAnimation:nil];
    
    if (user) {
        [NXLKeyChain save:self.keychain data:user];
    }
    if (self.completionHandler) {
        NSDictionary *fedAuthCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    user.siteurl, NSHTTPCookieOriginURL,
                                                                    @"FedAuth", NSHTTPCookieName,
                                                                    @"/", NSHTTPCookiePath,
                                                                    user.fedauthInfo, NSHTTPCookieValue,
                                                                    nil];
        
        NSDictionary *rtFaCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                    user.siteurl, NSHTTPCookieOriginURL,
                                    @"rtFa", NSHTTPCookieName,
                                    @"/", NSHTTPCookiePath,
                                    user.rtfaInfo, NSHTTPCookieValue,
                                    nil];
        
        
        NSHTTPCookie *fedAuthCookieObj = [NSHTTPCookie cookieWithProperties:fedAuthCookie];
        NSHTTPCookie *rtFaCookieObj = [NSHTTPCookie cookieWithProperties:rtFaCookie];
        
        NSArray *cookiesArray = @[fedAuthCookieObj, rtFaCookieObj];
        NXSharePointManager *sp = [[NXSharePointManager alloc] initWithURL:user.siteurl cookies:cookiesArray Type:kSPMgrSharePointOnline];
        self.completionHandler(sp, user, nil);
    }
    [self.presentingViewController dismissViewController:self];
}

-(void)Authentication:(NXSharepointOnlineAuthentication *)auth didAuthenticateFailWithError:(NSString *)error{
    if (self.completionHandler ) {
        NSError *retError = [[NSError alloc] initWithDomain:error code:10001 userInfo:nil];
        self.completionHandler(nil, nil, retError);
    }
    [self.indicator stopAnimation:nil];
    [self.confirmButton setEnabled:true];
    [self.spSiteText setEditable:true];
    [self.spUsernameText setEditable:true];
    [self.spPasswordText setEditable:true];
    [self.presentingViewController dismissViewController:self];
    
}
@end

