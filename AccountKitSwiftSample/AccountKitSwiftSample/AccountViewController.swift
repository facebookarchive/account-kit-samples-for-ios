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

import UIKit
import AccountKit

final class AccountViewController: UIViewController {
  
  // MARK: - outlets
  
  @IBOutlet weak var accountIDLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!

  // MARK: - properties
  
  fileprivate var accountKit = AKFAccountKit(responseType: .accessToken)
  
  // MARK: - view management
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    accountKit.requestAccount { [weak self] (account, error) in
      if let error = error {
        self?.accountIDLabel.text = "N/A"
        self?.titleLabel.text = "Error"
        self?.valueLabel.text = error.localizedDescription
      } else {
        self?.accountIDLabel.text = account?.accountID
        
        if let emailAddress = account?.emailAddress
          , emailAddress.characters.count > 0 {
          self?.titleLabel.text = "Email Address"
          self?.valueLabel.text = emailAddress
        } else if let phoneNumber = account?.phoneNumber {
          self?.titleLabel.text = "Phone Number"
          self?.valueLabel.text = phoneNumber.stringRepresentation()
        }
      }
    }
  }
  
  // MARK: - actions

  @IBAction func logOut(_ sender: AnyObject) {
    accountKit.logOut()
    navigationController!.popToRootViewController(animated: true)
  }
}
