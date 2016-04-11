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

#import "ConfigOptionListViewController.h"

#import "ConfigOption.h"

@implementation ConfigOptionListViewController
{
  NSUInteger _selectedConfigOptionValue;
}

#pragma mark - Public Properties

- (void)setConfigOptions:(NSArray<ConfigOption *> *)configOptions
{
  _configOptions = [configOptions copy];
  if ([self isViewLoaded]) {
    [self.tableView reloadData];
  }
}

#pragma mark - Public Methods

- (void)selectConfigOptionWithValue:(NSUInteger)value
{
  if (_selectedConfigOptionValue != value) {
    _selectedConfigOptionValue = value;
    [self _highlightSelectedValue];
  }
}

#pragma mark - View Management

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self _highlightSelectedValue];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"configOptionCell" forIndexPath:indexPath];
  ConfigOption *configOption = self.configOptions[indexPath.row];
  cell.textLabel.text = configOption.label;
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.configOptions.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  ConfigOption *configOption = self.configOptions[indexPath.row];
  _selectedConfigOptionValue = configOption.value;
  [self.delegate configOptionListViewController:self didSelectConfigOption:configOption];
}

#pragma mark - Helper Methods

- (void)_highlightSelectedValue
{
  if (![self isViewLoaded]) {
    return;
  }

  [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedConfigOptionValue inSection:0]
                              animated:NO
                        scrollPosition:UITableViewScrollPositionNone];
}

@end
