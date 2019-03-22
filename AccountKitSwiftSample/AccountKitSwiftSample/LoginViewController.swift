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

final class LoginViewController: UITableViewController {
  
  // MARK: - properties
  
  fileprivate var accountKit = AccountKit(responseType: .accessToken)
  fileprivate var pendingLoginViewController: AKFViewController? = nil
  fileprivate var showAccountOnAppear = false
  
  // MARK: - view management

  override func viewDidLoad() {
    super.viewDidLoad()
    
    showAccountOnAppear = accountKit.currentAccessToken != nil
    pendingLoginViewController = accountKit.viewControllerForLoginResume() as AKFViewController?
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if showAccountOnAppear {
      showAccountOnAppear = false
      presentWithSegueIdentifier("showAccount", animated: animated)
    } else if let viewController = pendingLoginViewController {
      prepareLoginViewController(viewController)
      if let viewController = viewController as? UIViewController {
        present(viewController, animated: animated, completion: nil)
        pendingLoginViewController = nil
      }
    }
  }
  
  // MARK: - actions

  @IBAction func loginWithPhone(_ sender: AnyObject) {
    if let viewController = accountKit.viewControllerForPhoneLogin(with: nil, state: nil) as AKFViewController? {
      prepareLoginViewController(viewController)
      if let viewController = viewController as? UIViewController {
        present(viewController, animated: true, completion: nil)
      }
    }
  }

  @IBAction func loginWithEmail(_ sender: AnyObject) {
    if let viewController = accountKit.viewControllerForEmailLogin(with: nil, state: nil) as AKFViewController? {
      prepareLoginViewController(viewController)
      if let viewController = viewController as? UIViewController {
        present(viewController, animated: true, completion: nil)
      }
    }
  }
  
  // MARK: - helpers
  
  fileprivate func prepareLoginViewController(_ loginViewController: AKFViewController) {
    loginViewController.delegate = self
  }

  fileprivate func presentWithSegueIdentifier(_ segueIdentifier: String, animated: Bool) {
    if animated {
      performSegue(withIdentifier: segueIdentifier, sender: nil)
    } else {
      UIView.performWithoutAnimation {
        self.performSegue(withIdentifier: segueIdentifier, sender: nil)
      }
    }
  }
}

// MARK: - AKFViewControllerDelegate extension

extension LoginViewController: AKFViewControllerDelegate {
  func viewController(_ viewController: UIViewController & AKFViewController,
                      didCompleteLoginWith accessToken: AccessToken,
                      state: String) {
    presentWithSegueIdentifier("showAccount", animated: false)
  }

  func viewController(_ viewController: UIViewController & AKFViewController, didFailWithError error: Error) {
    print("\(viewController) did fail with error: \(error)")
  }
}
