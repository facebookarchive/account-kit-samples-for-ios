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

#import "ReverbActionBarView.h"

#import "ReverbTheme.h"

@implementation ReverbActionBarView
{
  CGFloat _top;
  CGFloat _height;
  UIButton *_backButton;
  UILabel *_titleLabel;
  UIImageView *_appIconView;
  NSArray<NSLayoutConstraint *> *_verticalConstraints;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithState:(AKFLoginFlowState)state
                        theme:(ReverbTheme *)theme
                     delegate:(id<ReverbActionBarViewDelegate>)delegate
{
  if ((self = [super initWithFrame:CGRectZero])) {
    self.delegate = delegate;
    _top = 28.0;
    _height = 0.0;

    self.backgroundColor = theme.headerBackgroundColor;

    _backButton = nil;
    UIImage *backArrowImage = theme.backArrowImage;
    if (backArrowImage != nil) {
      _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
      _backButton.translatesAutoresizingMaskIntoConstraints = NO;
      [_backButton setImage:backArrowImage forState:UIControlStateNormal];
      [_backButton addTarget:self action:@selector(_back:) forControlEvents:UIControlEventTouchUpInside];
      [_backButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [_backButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      _backButton.contentEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15);
      [self addSubview:_backButton];
    }

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = theme.headerBackgroundColor;
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _titleLabel.text = [self _titleForState:state theme:theme];
    _titleLabel.textColor = theme.headerTextColor;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];

    _appIconView = nil;
    UIImage *appIconImage = theme.appIconImage;
    if (appIconImage != nil) {
      _appIconView = [[UIImageView alloc] initWithImage:appIconImage];
      _appIconView.contentMode = UIViewContentModeCenter;
      _appIconView.translatesAutoresizingMaskIntoConstraints = NO;
      [_appIconView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [_appIconView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [self addSubview:_appIconView];
    }
    [self _createHorizontalConstraints];
    [self _createVerticalConstraints];
  }
  return self;
}

-(void)safeAreaInsetsDidChange {
  if (@available(iOS 11.0, *)) {
    _top = self.safeAreaInsets.top;
    [self needsUpdateConstraints];
    [self removeConstraints:_verticalConstraints];
    [self _createVerticalConstraints];
    [self invalidateIntrinsicContentSize];
  }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(UIViewNoIntrinsicMetric, /* top */ _top + /* content */ _height + /* bottom */ 12.0);
}

- (CGSize)sizeThatFits:(CGSize)size
{
  return CGSizeMake(size.width, self.intrinsicContentSize.height);
}

#pragma mark - Helper Methods

- (void)_back:(id)sender
{
  [self.delegate reverbActionBarViewDidTapBack:self];
}

- (NSString *)_titleForState:(AKFLoginFlowState)state theme:(ReverbTheme *)theme
{
  NSString *title;
  switch (state) {
    case AKFLoginFlowStateNone:
    case AKFLoginFlowStateResendCode:
      return nil;
    case AKFLoginFlowStatePhoneNumberInput:
      title = @"Enter your phone number";
      break;
    case AKFLoginFlowStateEmailInput:
      title = @"Enter your email address";
      break;
    case AKFLoginFlowStateSendingCode:
      title = @"Sending your code...";
      break;
    case AKFLoginFlowStateSentCode:
      title = @"Sent!";
      break;
    case AKFLoginFlowStateCodeInput:
      title = @"Enter your code";
      break;
    case AKFLoginFlowStateEmailVerify:
      title = @"Open the email and confirm your address";
      break;
    case AKFLoginFlowStateVerifyingCode:
      title = @"Verifying your code...";
      break;
    case AKFLoginFlowStateVerified:
      title = @"Done!";
      break;
    case AKFLoginFlowStateCountryCode:
      title = @"Select a Country Code";
      break;
    case AKFLoginFlowStateError:
      title = @"We're sorry, something went wrong.";
      break;
  }
  if (theme.textUppercase) {
    title = [title uppercaseString];
  }
  return title;
}

-(void)_createHorizontalConstraints
{
  NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(_titleLabel);
  if (_backButton == nil) {
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_titleLabel]" options:0 metrics:nil views:views]];
  } else {
    NSDictionary<NSString *, id> *_backButtonViews = NSDictionaryOfVariableBindings(_backButton, _titleLabel);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backButton][_titleLabel]" options:0 metrics:nil views:_backButtonViews]];
  }
  if (_appIconView == nil) {
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-|" options:0 metrics:nil views:views]];
  } else {
    NSDictionary<NSString *, id> *_appIconViews = NSDictionaryOfVariableBindings(_appIconView, _titleLabel);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-[_appIconView]-|" options:0 metrics:nil views:_appIconViews]];
  }
}

-(void)_createVerticalConstraints
{
  NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(_titleLabel);
  NSDictionary<NSString *, id> *metrics = @{
                                            @"top": @(_top),
                                            };
  NSMutableArray<NSLayoutConstraint *> *constraints =
  [[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[_titleLabel]-|" options:0 metrics:metrics views:views] mutableCopy];

  if (_backButton != nil) {
    NSDictionary<NSString *, id> *_backButtonViews = NSDictionaryOfVariableBindings(_backButton, _titleLabel);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[_backButton]-|" options:0 metrics:metrics views:_backButtonViews]];
  }
  if (_appIconView != nil) {
    NSDictionary<NSString *, id> *_appIconViews = NSDictionaryOfVariableBindings(_appIconView, _titleLabel);
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[_appIconView]-|" options:0 metrics:metrics views:_appIconViews]];
  }
  [self addConstraints:constraints];
  _height = MAX(_height, [_titleLabel intrinsicContentSize].height);
  _height = MAX(_height, [_backButton intrinsicContentSize].height);
  _height = MAX(_height, [_appIconView intrinsicContentSize].height);
  _verticalConstraints = constraints;
}

@end
