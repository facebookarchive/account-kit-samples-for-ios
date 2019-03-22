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
#import "ReverbTheme.h"
#import "ReverbUIManager.h"
#import "Theme.h"

@interface LoginViewController () <AKFViewControllerDelegate, ConfigOptionListViewControllerDelegate, ReverbUIManagerDelegate>
@end

@implementation LoginViewController
{
  AKFAccountKit *_accountKit;
  NSString *_authorizationCode;
  AKFButtonType _confirmButtonType;
  BOOL _enableSendToFacebook;
  BOOL _enableGetACall;
  AKFButtonType _entryButtonType;
  AKFHeaderTextType _headerTextType;
  NSString *_inputState;
  NSString *_outputState;
  UIViewController<AKFViewController> *_pendingLoginViewController;
  BOOL _showAccountOnAppear;
  AKFTextPosition _textPosition;
  ThemeType _themeType;
  BOOL _useAdvancedUIManager;
  BOOL _useBackgroundImage;
  AKFBackgroundTint _backgroundTint;
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
  _enableGetACall = YES;

  [self _updateThemeType:_themeType];
  [self _updateEntryButtonType:_entryButtonType];
  [self _updateConfirmButtonType:_confirmButtonType];
  [self _updateTextPosition:_textPosition];
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
      [options addObject:[[ConfigOption alloc] initWithValue:i label:[Theme labelForThemeType:i]]];
    }
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeTheme
                                         options:options
                                   selectedValue:_themeType];
  } else if ([identifier isEqualToString:@"showEntryButtonTypeList"]) {
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeEntryButtonType
                                         options:[self _buttonTypeOptions]
                                   selectedValue:_entryButtonType];
  } else if ([identifier isEqualToString:@"showConfirmButtonTypeList"]) {
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeConfirmButtonType
                                         options:[self _buttonTypeOptions]
                                   selectedValue:_confirmButtonType];
  } else if ([identifier isEqualToString:@"showTextPositionList"]) {
    [self _prepareConfigOptionListViewController:(ConfigOptionListViewController *)destinationViewController
                                        withType:ConfigOptionTypeTextPosition
                                         options:[self _textPositionOptions]
                                   selectedValue:_textPosition];
  }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  if (![identifier isEqualToString:@"showEntryButtonTypeList"] &&
      ![identifier isEqualToString:@"showConfirmButtonTypeList"] &&
      ![identifier isEqualToString:@"showTextPositionList"]) {
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
  viewController.enableGetACall = _enableGetACall;
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
  [self _updateCells];
}

- (void)toggleBackgroundImage:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _useBackgroundImage = switchControl.on;
  [self _setCell:self.backgroundTintSwitchCell enabled:_useBackgroundImage];
  [self _setCell:self.tintOpacitySliderCell enabled:_useBackgroundImage];
}

- (void)toggleBackgroundTint:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  if (switchControl.on) {
    _backgroundTint = AKFBackgroundTintBlack;
  } else {
    _backgroundTint = AKFBackgroundTintWhite;
  }
}

- (void)toggleEnableSendToFacebook:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _enableSendToFacebook = switchControl.on;
}

- (void)toggleEnableGetACall:(id)sender
{
  if (![sender isKindOfClass:[UISwitch class]]) {
    return;
  }
  UISwitch *switchControl = (UISwitch *)sender;
  _enableGetACall = switchControl.on;
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
  _headerTextType = switchControl.on ? AKFHeaderTextTypeAppName : AKFHeaderTextTypeLogin;
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

- (void)viewControllerDidCancel:(UIViewController<AKFViewController> *)viewController
{
  NSLog(@"%@ did cancel", viewController);
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
    case ConfigOptionTypeTextPosition:
      [self _updateTextPosition:(AKFTextPosition)configOption.value];
      break;
    case ConfigOptionTypeTheme:
      [self _updateThemeType:(ThemeType)configOption.value];
      break;
    case ConfigOptionTypeNone:
      break;
  }
  [configOptionListViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark - ReverbUIManagerDelegate

- (void)reverbUIManager:(ReverbUIManager *)reverbUIManager didSwitchLoginType:(AKFLoginType)loginType
{
  UIViewController<AKFViewController> *viewController;
  switch (loginType) {
    case AKFLoginTypeEmail:
      viewController = [_accountKit viewControllerForEmailLoginWithEmail:nil state:_inputState];
      break;
    case AKFLoginTypePhone:
      viewController = [_accountKit viewControllerForPhoneLoginWithPhoneNumber:nil state:_inputState];
      viewController.enableSendToFacebook = _enableSendToFacebook;
      viewController.enableGetACall = _enableGetACall;
      break;
  }
  [self _prepareLoginViewController:viewController];
  _pendingLoginViewController = viewController;
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

- (NSString *)_labelForTextPosition:(AKFTextPosition)textPosition
{
  switch (textPosition) {
    case AKFTextPositionDefault:
      return @"Default";
    case AKFTextPositionAboveBody:
      return @"Above Body";
    case AKFTextPositionBelowBody:
      return @"Below Body";
  }
}

- (void)_prepareLoginViewController:(UIViewController<AKFViewController> *)loginViewController
{
  Theme *theme;
  ReverbTheme *reverbTheme = nil;
  if ([Theme isReverbTheme:_themeType]) {
    reverbTheme = [ReverbTheme themeWithType:_themeType];
    theme = reverbTheme;
  } else {
    theme = [Theme themeWithType:_themeType];
    if (theme) {
      theme.headerTextType = _headerTextType;
    }
  }

  if ([Theme isSkinUI:_themeType]) {
    if (_useBackgroundImage) {
      loginViewController.uiManager =
        [[AKFSkinManager alloc] initWithSkinType:[Theme skinForThemeType:_themeType]
                                    primaryColor:nil
                                 backgroundImage:[UIImage imageNamed:@"dog"]
                                  backgroundTint:_backgroundTint
                                   tintIntensity:_tintOpacitySlider.value];
    } else {
      loginViewController.uiManager =
        [[AKFSkinManager alloc] initWithSkinType:[Theme skinForThemeType:_themeType]];
    }
  } else if (_useAdvancedUIManager) {
    if ([Theme isReverbTheme:_themeType]) {
      loginViewController.uiManager =
        [[ReverbUIManager alloc] initWithConfirmButtonType:_confirmButtonType
                                           entryButtonType:_entryButtonType
                                                 loginType:loginViewController.loginType
                                              textPosition:_textPosition
                                                     theme:reverbTheme
                                                  delegate:self];
    } else {
      loginViewController.uiManager =
        [[AdvancedUIManager alloc] initWithTheme:theme
                               confirmButtonType:_confirmButtonType
                                 entryButtonType:_entryButtonType
                                       loginType:loginViewController.loginType
                                    textPosition:_textPosition];
    }
  } else {
    loginViewController.theme = theme;
  }

  loginViewController.delegate = self;
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

- (void)_setCell:(UITableViewCell *)cell enabled:(BOOL)enabled
{
  for (UIView *view in cell.contentView.subviews) {
    if ([view isKindOfClass:[UILabel class]]) {
      ((UILabel *)view).enabled = enabled;
    } else if ([view isKindOfClass:[UIControl class]]) {
      ((UIControl *)view).enabled = enabled;
    }
  }
}

- (void)_setCell:(UITableViewCell *)cell selectable:(BOOL)selectable
{
  cell.selectionStyle = selectable ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
}

- (NSArray<ConfigOption *> *)_textPositionOptions
{
  NSMutableArray<ConfigOption *> *options = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < AKFTextPositionCount; ++i) {
    [options addObject:[[ConfigOption alloc] initWithValue:i label:[self _labelForTextPosition:i]]];
  }
  return [options copy];
}

- (void)_updateCells
{
  NSArray<UITableViewCell *> *unselectableCells = self.unselectableCells;
  for (UITableViewCell *cell in unselectableCells) {
    [self _setCell:cell selectable:NO];
  }
  for (UITableViewCell *cell in self.advancedUICells) {
    [self _setCell:cell enabled:_useAdvancedUIManager];
    [self _setCell:cell selectable:(_useAdvancedUIManager && ![unselectableCells containsObject:cell])];
  }
}

- (void)_updateConfirmButtonType:(AKFButtonType)buttonType
{
  self.currentConfirmButtonTypeLabel.text = [self _labelForButtonType:buttonType];
  _confirmButtonType = buttonType;
}

- (void)_updateEntryButtonType:(AKFButtonType)buttonType
{
  self.currentEntryButtonTypeLabel.text = [self _labelForButtonType:buttonType];
  _entryButtonType = buttonType;
}

- (void)_updateTextPosition:(AKFTextPosition)textPosition
{
  self.currentTextPositionLabel.text = [self _labelForTextPosition:textPosition];
  _textPosition = textPosition;
}

- (void)_updateThemeType:(ThemeType)themeType
{
  _themeType = themeType;
  self.currentThemeLabel.text = [Theme labelForThemeType:_themeType];

  if ([Theme isReverbTheme:_themeType]) {
    [self _setCell:self.advancedUISwitchCell enabled:NO];
    UISwitch *advancedUISwitch = self.advancedUISwitch;
    if (!advancedUISwitch.on) {
      advancedUISwitch.on = YES;
      [self toggleAdvancedUI:advancedUISwitch];
    }
  } else if ([Theme isSkinUI:_themeType]) {
    [self _setCell:self.advancedUISwitchCell enabled:NO];

    UISwitch *advancedUISwitch = self.advancedUISwitch;
    if (advancedUISwitch.on) {
      advancedUISwitch.on = NO;
      [self toggleAdvancedUI:advancedUISwitch];
    }

    if (_themeType == ThemeTypeDog) {
      UISwitch *backgroundImageSwitch = self.backgroundImageSwitch;
      if (!backgroundImageSwitch.on) {
        backgroundImageSwitch.on = YES;
        [self toggleBackgroundImage:backgroundImageSwitch];
      }
    }
  } else {
    [self _setCell:self.advancedUISwitchCell enabled:YES];
  }

  if ([Theme isSkinUI:_themeType]) {
    [self _setCell:self.backgroundImageSwitchCell enabled:YES];
    [self _setCell:self.backgroundTintSwitchCell enabled:_useBackgroundImage];
    [self _setCell:self.tintOpacitySliderCell enabled:_useBackgroundImage];
  } else {
    [self _setCell:self.backgroundImageSwitchCell enabled:NO];
    [self _setCell:self.backgroundTintSwitchCell enabled:NO];
    [self _setCell:self.tintOpacitySliderCell enabled:NO];
    self.backgroundImageSwitch.on = NO;
    self.backgroundTintSwitch.on = NO;
    _backgroundTint = AKFBackgroundTintWhite;
    _useBackgroundImage = NO;
  }
}

@end
