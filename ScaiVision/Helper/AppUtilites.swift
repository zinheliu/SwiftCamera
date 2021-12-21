//
//  AppUtilites.swift
//  Luxury Library
//
//  Created by Gabani on 06/06/20.
//  Copyright © 2020 Ankit Gabani. All rights reserved.
//

import UIKit
import Foundation

class AppUtilites: NSObject {
    
    class var sharedInstance: AppUtilites {
        struct Static {
            static let instance: AppUtilites = AppUtilites()
        }
        return Static.instance
    }
    
    class var deviceHasTopNotch: Bool {
        if #available(iOS 11.0,  *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }
    
    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    func getViewController(controllerName: String) -> UIViewController {
        return mainStoryboard.instantiateViewController(withIdentifier: controllerName)
    }
    
    class func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    class func isValidPhone(value: String) -> Bool {
        let PHONE_REGEX = "^((\\+)|(00))[0-9]{6,14}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result =  phoneTest.evaluate(with: value)
        return result
    }

    class func isPasswordValid(_ password : String) -> Bool{
        let regex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[$@$!%*?&])[A-Za-z\\d$@$!%*?&]{6,}"
        let isMatched = NSPredicate(format:"SELF MATCHES %@", regex).evaluate(with: password)
        if(isMatched  == true) {
            return true
        }  else {
            return false
        }
    }

    
    // MARK: - AlertView
    
    class func showAlert(title: String, message: String, cancelButtonTitle: String) {
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: cancelButtonTitle, style: .default))
        window.visibleViewController?.present(alertView, animated: true)
        
    }
    
    class func showAlert(title: String, message: String, actionButtonTitle: String, completionHandler : @escaping () -> Void) {
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertView.addAction(UIAlertAction(title: actionButtonTitle, style: .default, handler: { (_) in
            completionHandler()
        }))
        
        window.visibleViewController?.present(alertView, animated: true)
        
    }
    
    class func showAlert(title: String, message: String, actionButtonTitle: String, cancelButtonTitle: String, completionHandler : @escaping () -> Void) {
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertView.addAction(UIAlertAction(title: actionButtonTitle, style: .default, handler: { (_) in
            completionHandler()
        }))
        
        alertView.addAction(UIAlertAction(title: cancelButtonTitle, style: .default, handler: nil))
        
        window.visibleViewController?.present(alertView, animated: true)
        
    }
    
}

public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }
    
    static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}
