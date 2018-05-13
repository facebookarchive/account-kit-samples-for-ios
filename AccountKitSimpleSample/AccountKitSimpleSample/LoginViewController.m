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

#import <AccountKit/AccountKit.h>
#import "LoginViewController.h"
#import "AccountViewController.h"
#import "AdvancedUIManager.h"

@interface LoginViewController () <AKFViewControllerDelegate>
@end

@implementation LoginViewController
{
  AKFAccountKit *_accountKit;
  NSString *_authorizationCode;
  UIViewController<AKFViewController> *_pendingLoginViewController;
  BOOL _showAccountOnAppear;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];

  if (_accountKit == nil) {
    _accountKit = [[AKFAccountKit alloc] initWithResponseType:AKFResponseTypeAccessToken];
  }

  _showAccountOnAppear = (_accountKit.currentAccessToken != nil);
  _pendingLoginViewController = [_accountKit viewControllerForLoginResume];
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

#pragma mark - Actions

- (void)loginWithEmail:(id)sender
{
  UIViewController<AKFViewController> *viewController = [_accountKit viewControllerForEmailLoginWithEmail:nil
                                                                                                    state:nil];
  [self _prepareLoginViewController:viewController];
  [self presentViewController:viewController animated:YES completion:NULL];
}

- (void)loginWithPhone:(id)sender
{
  UIViewController<AKFViewController> *viewController = [_accountKit viewControllerForPhoneLoginWithPhoneNumber:nil
                                                                                                          state:nil];
  [self _prepareLoginViewController:viewController];
  [self presentViewController:viewController animated:YES completion:NULL];
}

#pragma mark - AKFViewControllerDelegate;

- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAccessToken:(id<AKFAccessToken>)accessToken state:(NSString *)state
{
  [self _presentWithSegueIdentifier:@"showAccount" animated:NO];
}

- (void)viewController:(UIViewController<AKFViewController> *)viewController didFailWithError:(NSError *)error
{
  NSLog(@"%@ did fail with error: %@", viewController, error);
}

#pragma mark - Helper Methods

- (void)_prepareLoginViewController:(UIViewController<AKFViewController> *)loginViewController
{
  loginViewController.advancedUIManager = [[AdvancedUIManager alloc] init];
  loginViewController.delegate = self;
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

@end
