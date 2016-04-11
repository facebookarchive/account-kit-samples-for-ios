// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "LoginViewController.h"

#import <AccountKit/AccountKit.h>

#import "AccountViewController.h"
#import "AdvancedUIManager.h"
#import "AuthorizationCodeViewController.h"
#import "ConfigOption.h"
#import "ConfigOptionListViewController.h"
#import "Themes.h"

@interface LoginViewController () <AKFViewControllerDelegate, ConfigOptionListViewControllerDelegate>
@end

@implementation LoginViewController
{
  AKFAccountKit *_accountKit;
  AdvancedUIManager *_advancedUIManager;
  NSString *_authorizationCode;
  BOOL _enableSendToFacebook;
  NSString *_inputState;
  NSString *_outputState;
  UIViewController<AKFViewController> *_pendingLoginViewController;
  BOOL _showAccountOnAppear;
  AKFTheme *_theme;
  ThemeType _themeType;
  BOOL _useAdvancedUIManager;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];

  if (_accountKit == nil) {
    _accountKit = [[AKFAccountKit alloc] initWithResponseType:AKFResponseTypeAccessToken];
  }

  _showAccountOnAppear = ([_accountKit currentAccessToken] != nil);
  _pendingLoginViewController = [_accountKit viewControllerForLoginResume];
  _enableSendToFacebook = YES;

  [self _updateThemeType:_themeType];
  [self _updateEntryButtonType:_advancedUIManager.entryButtonType];
  [self _updateConfirmButtonType:_advancedUIManager.confirmButtonType];
  [self _updateCells];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (_showAccountOnAppear) {
    _showAccountOnAppear = NO;
    [self _presentWithSegueIdentifier:@"showAccount" animated:animated];
  } else if (_pendingLoginViewController != nil) {
    [self _prepareLoginViewController:_pendingLoginViewController];
    [self presentViewController:_pendingLoginViewController animated:animated completion:NULL];
    _pendingLoginViewController = nil;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  UIViewController *destinationViewController = segue.destinationViewController;
  NSString *identifier = segue.identifier;
  if ([destinationViewController isKindOfClass:[AccountViewController class]]) {
    ((AccountViewController *)destinationViewController).accountKitState = _outputState;
  } else if ([destinationViewController isKindOfClass:[AuthorizationCodeViewController class]]) {
    ((AuthorizationCodeViewController *)destinationViewController).accountKitAuthorizationCode = _authorizationCode;
    ((AuthorizationCodeViewController *)destinationViewController).accountKitState = _outputState;
  } else if ([identifier isEqualToString:@"showThemeList"]) {
    NSMutableArray<ConfigOption *> *options = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < ThemeTypeCount; ++i) {
      [options addObject:[[ConfigOption alloc] initWithValue:i label:[Themes labelForThemeType:i]]];
    }
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeTheme
                                         options:options
                                   selectedValue:_themeType];
  } else if ([identifier isEqualToString:@"showEntryButtonTypeList"]) {
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeEntryButtonType
                                         options:[self _buttonTypeOptions]
                                   selectedValue:_advancedUIManager.entryButtonType];
  } else if ([identifier isEqualToString:@"showConfirmButtonTypeList"]) {
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeConfirmButtonType
                                         options:[self _buttonTypeOptions]
                                   selectedValue:_advancedUIManager.confirmButtonType];
  }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  if (![identifier isEqualToString:@"showEntryButtonTypeList"] &&
      ![identifier isEqualToString:@"showConfirmButtonTypeList"]) {
    return YES;
  }

  return _useAdvancedUIManager;
}

#pragma mark - Actions

- (void)loginWithEmail:(id)email
{
  UIViewController<AKFViewController> *viewController = [_accountKit viewControllerForEmailLoginWithEmail:nil
                                                                                                    state:_inputState];
  [self _prepareLoginViewController:viewController];
  [self presentViewController:viewController animated:YES completion:NULL];
}

- (void)loginWithPhone:(id)sender
{
  UIViewController<AKFViewController> *viewController = [_accountKit viewControllerForPhoneLoginWithPhoneNumber:nil
                                                                                                          state:_inputState];
  viewController.enableSendToFacebook = _enableSendToFacebook;
  [self _prepareLoginViewController:viewController];
  [self presentViewController:viewController animated:YES completion:NULL];
}

- (void)toggleAdvancedUI:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _useAdvancedUIManager = switchControl.on;
  if (_useAdvancedUIManager) {
    [self _ensureAdvancedUIManager];
  }
  [self _updateCells];
}

- (void)toggleResponseType:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _accountKit = [[AKFAccountKit alloc] initWithResponseType:(switchControl.on ?
                                                             AKFResponseTypeAccessToken :
                                                             AKFResponseTypeAuthorizationCode)];
}

- (void)toggleSendState:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _inputState = switchControl.on ? [self _generateState] : nil;
}

- (IBAction)toggleEnableSendToFacebook:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _enableSendToFacebook = switchControl.on;
}

- (NSString *)_generateState
{
  NSString *UUIDString = [[NSUUID UUID] UUIDString];
  return [UUIDString substringToIndex:[UUIDString rangeOfString:@"-"].location];
}

- (void)toggleTitle:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _theme.headerTextType = switchControl.on ? AKFHeaderTextTypeAppName : AKFHeaderTextTypeLogin;
}

#pragma mark - AKFViewControllerDelegate;

- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAccessToken:(id<AKFAccessToken>)accessToken state:(NSString *)state
{
  _outputState = [state copy];
  [self _presentWithSegueIdentifier:@"showAccount" animated:NO];
}

- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAuthorizationCode:(NSString *)code state:(NSString *)state
{
  _authorizationCode = [code copy];
  _outputState = [state copy];
  [self _presentWithSegueIdentifier:@"showAuthorizationCode" animated:NO];
}

- (void)viewController:(UIViewController<AKFViewController> *)viewController didFailWithError:(NSError *)error
{
  NSLog(@"%@ did fail with error: %@", viewController, error);
}

#pragma mark - ConfigOptionListViewControllerDelegate

- (void)configOptionListViewController:(ConfigOptionListViewController *)configOptionListViewController
                 didSelectConfigOption:(ConfigOption *)configOption
{
  switch (configOptionListViewController.configOptionType) {
    case ConfigOptionTypeConfirmButtonType:
      [self _updateConfirmButtonType:(AKFButtonType)configOption.value];
      break;
    case ConfigOptionTypeEntryButtonType:
      [self _updateEntryButtonType:(AKFButtonType)configOption.value];
      break;
    case ConfigOptionTypeTheme:
      [self _updateThemeType:(ThemeType)configOption.value];
      break;
    case ConfigOptionTypeNone:
      break;
  }
  [configOptionListViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helper Methods

- (NSArray<ConfigOption *> *)_buttonTypeOptions
{
  NSMutableArray<ConfigOption *> *options = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < AKFButtonTypeCount; ++i) {
    [options addObject:[[ConfigOption alloc] initWithValue:i label:[self _labelForButtonType:i]]];
  }
  return [options copy];
}

- (void)_ensureAdvancedUIManager
{
  if (_advancedUIManager == nil) {
    _advancedUIManager = [[AdvancedUIManager alloc] init];
  }
}

- (NSString *)_labelForButtonType:(AKFButtonType)buttonType
{
  switch (buttonType) {
    case AKFButtonTypeDefault:
      return @"Default";
    case AKFButtonTypeBegin:
      return @"Begin";
    case AKFButtonTypeConfirm:
      return @"Confirm";
    case AKFButtonTypeContinue:
      return @"Continue";
    case AKFButtonTypeLogIn:
      return @"Log In";
    case AKFButtonTypeNext:
      return @"Next";
    case AKFButtonTypeOK:
      return @"OK";
    case AKFButtonTypeSend:
      return @"Send";
    case AKFButtonTypeStart:
      return @"Start";
    case AKFButtonTypeSubmit:
      return @"Submit";
  }
}

- (void)_prepareLoginViewController:(UIViewController<AKFViewController> *)loginViewController
{
  loginViewController.advancedUIManager = _useAdvancedUIManager ? _advancedUIManager : nil;
  loginViewController.delegate = self;
  loginViewController.theme = _theme;
}

- (void)_prepareConfigOptionListViewController:(ConfigOptionListViewController *)viewController
                                      withType:(ConfigOptionType)type
                                       options:(NSArray<ConfigOption *> *)options
                                 selectedValue:(NSUInteger)selectedValue
{
  if (![viewController isKindOfClass:[ConfigOptionListViewController class]]) {
    return;
  }
  viewController.configOptions = options;
  viewController.configOptionType = type;
  viewController.delegate = self;
  [viewController selectConfigOptionWithValue:selectedValue];
}

- (void)_presentWithSegueIdentifier:(NSString *)segueIdentifier animated:(BOOL)animated
{
  if (animated) {
    [self performSegueWithIdentifier:segueIdentifier sender:nil];
  } else {
    [UIView performWithoutAnimation:^{
      [self performSegueWithIdentifier:segueIdentifier sender:nil];
    }];
  }
}

- (void)_setCell:(UITableViewCell *)cell enabled:(BOOL)enabled selectable:(BOOL)selectable
{
  cell.selectionStyle = selectable ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
  for (UIView *view in cell.contentView.subviews) {
    if ([view isKindOfClass:[UILabel class]]) {
      ((UILabel *)view).enabled = enabled;
    } else if ([view isKindOfClass:[UIControl class]]) {
      ((UIControl *)view).enabled = enabled;
    }
  }
}

- (void)_updateCells
{
  NSArray<UITableViewCell *> *unselectableCells = self.unselectableCells;
  for (UITableViewCell *cell in unselectableCells) {
    [self _setCell:cell enabled:YES selectable:NO];
  }
  for (UITableViewCell *cell in self.advancedUICells) {
    [self _setCell:cell
           enabled:_useAdvancedUIManager
        selectable:(_useAdvancedUIManager && ![unselectableCells containsObject:cell])];
  }
}

- (void)_updateConfirmButtonType:(AKFButtonType)buttonType
{
  self.currentConfirmButtonTypeLabel.text = [self _labelForButtonType:buttonType];
  if (buttonType != AKFButtonTypeDefault) {
    [self _ensureAdvancedUIManager];
  }
  _advancedUIManager.confirmButtonType = buttonType;
}

- (void)_updateEntryButtonType:(AKFButtonType)buttonType
{
  self.currentEntryButtonTypeLabel.text = [self _labelForButtonType:buttonType];
  if (buttonType != AKFButtonTypeDefault) {
    [self _ensureAdvancedUIManager];
  }
  _advancedUIManager.entryButtonType = buttonType;
}

- (void)_updateThemeType:(ThemeType)themeType
{
  _themeType = themeType;
  AKFTheme *theme = [Themes themeWithType:themeType];
  if (_theme != nil){
    theme.headerTextType = _theme.headerTextType;
  }
  _theme = theme;
  self.currentThemeLabel.text = [Themes labelForThemeType:themeType];
}

@end
