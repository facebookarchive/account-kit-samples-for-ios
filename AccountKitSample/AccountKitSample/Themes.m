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

#import "Themes.h"

#import <UIKit/UIKit.h>

const NSUInteger ThemeTypeCount = 6;

@implementation Themes

+ (NSString *)labelForThemeType:(ThemeType)themeType
{
  switch (themeType) {
    case ThemeTypeDefault:
      return @"Default";
    case ThemeTypeSalmon:
      return @"Salmon";
    case ThemeTypeYellow:
      return @"Yellow";
    case ThemeTypeRed:
      return @"Red";
    case ThemeTypeDog:
      return @"Dog";
    case ThemeTypeBicycle:
      return @"Bicycle";
  }
}

+ (AKFTheme *)themeWithType:(ThemeType)themeType
{
  switch (themeType) {
    case ThemeTypeDefault:
      return [AKFTheme defaultTheme];
      break;
    case ThemeTypeSalmon:
      return [self salmonTheme];
      break;
    case ThemeTypeYellow:
      return [self yellowTheme];
      break;
    case ThemeTypeRed:
      return [self redTheme];
      break;
    case ThemeTypeDog:
      return [self dogTheme];
      break;
    case ThemeTypeBicycle:
      return [self bicycleTheme];
      break;
  }
}

+ (AKFTheme *)salmonTheme
{
  AKFTheme *theme = [AKFTheme themeWithPrimaryColor:[UIColor whiteColor]
                                   primaryTextColor:[self _colorWithHex:0xff565a5c]
                                     secondaryColor:[self _colorWithHex:0xccffe5e5]
                                 secondaryTextColor:[self _colorWithHex:0xff565a5c]
                                     statusBarStyle:UIStatusBarStyleDefault];
  theme.buttonBackgroundColor = [self _colorWithHex:0xffff5a5f];
  theme.buttonTextColor = [UIColor whiteColor];
  theme.iconColor = [self _colorWithHex:0xffff5a5f];
  theme.inputTextColor = [self _colorWithHex:0xff44566b];
  return theme;
}

+ (AKFTheme *)yellowTheme
{
  AKFTheme *theme = [AKFTheme outlineThemeWithPrimaryColor:[self _colorWithHex:0xfff4bf56]
                                          primaryTextColor:[UIColor whiteColor]
                                        secondaryTextColor:[self _colorWithHex:0xff44566b]
                                            statusBarStyle:UIStatusBarStyleDefault];
  theme.buttonTextColor = [UIColor whiteColor];
  return theme;
}

+ (AKFTheme *)redTheme
{
  AKFTheme *theme = [AKFTheme outlineThemeWithPrimaryColor:[self _colorWithHex:0xff333333]
                                          primaryTextColor:[UIColor whiteColor]
                                        secondaryTextColor:[self _colorWithHex:0xff151515]
                                            statusBarStyle:UIStatusBarStyleLightContent];
  theme.backgroundColor = [self _colorWithHex:0xfff7f7f7];
  theme.buttonBackgroundColor = [self _colorWithHex:0xffe02727];
  theme.buttonBorderColor = [self _colorWithHex:0xffe02727];
  theme.inputBorderColor = [self _colorWithHex:0xffe02727];
  return theme;
}

+ (AKFTheme *)dogTheme
{
  AKFTheme *theme = [AKFTheme themeWithPrimaryColor:[UIColor whiteColor]
                                   primaryTextColor:[self _colorWithHex:0xff44566b]
                                     secondaryColor:[self _colorWithHex:0xccffffff]
                                 secondaryTextColor:[UIColor whiteColor]
                                     statusBarStyle:UIStatusBarStyleDefault];
  theme.backgroundColor = [self _colorWithHex:0x994e7e24];
  theme.backgroundImage = [UIImage imageNamed:@"dog"];
  theme.inputTextColor = [self _colorWithHex:0xff44566b];
  return theme;
}

+ (AKFTheme *)bicycleTheme
{
  AKFTheme *theme = [AKFTheme outlineThemeWithPrimaryColor:[self _colorWithHex:0xffff5a5f]
                                          primaryTextColor:[UIColor whiteColor]
                                        secondaryTextColor:[UIColor whiteColor]
                                            statusBarStyle:UIStatusBarStyleLightContent];
  theme.backgroundImage = [UIImage imageNamed:@"bicycle"];
  theme.backgroundColor = [self _colorWithHex:0x66000000];
  theme.inputBackgroundColor = [self _colorWithHex:0x00000000];
  theme.inputBorderColor = [UIColor whiteColor];
  return theme;
}

+ (UIColor *)_colorWithHex:(NSUInteger)hex
{
  CGFloat alpha = ((CGFloat)((hex & 0xff000000) >> 24)) / 255.0;
  CGFloat red = ((CGFloat)((hex & 0x00ff0000) >> 16)) / 255.0;
  CGFloat green = ((CGFloat)((hex & 0x0000ff00) >> 8)) / 255.0;
  CGFloat blue = ((CGFloat)((hex & 0x000000ff) >> 0)) / 255.0;
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
