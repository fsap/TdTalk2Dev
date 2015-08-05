//
//  TTAlertController.swift
//  TdTalk2
//
//  Created by Fujiwara on 2015/07/26.
//  Copyright (c) 2015年 FSAP. All rights reserved.
//

import UIKit

class TTAlertController : UIViewController {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
        
    }
    
    // ダイアログを表示
    // ※OS分岐ではなくobjc_getClassを使う方が良いかもしれない
    func show(parentView:UIViewController?, title:String, message:String)->Void {
        // OS7,8で出し分け
        if (isOS8()) {
            var alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            if parentView != nil {
                // action
                let okAction = UIAlertAction(title: NSLocalizedString("dialog_ok", comment:""), style: UIAlertActionStyle.Default , handler: { (action:UIAlertAction!) -> Void in
                    alertController.dismissViewControllerAnimated(false, completion: nil)
                })
                alertController.addAction(okAction)
                
                var viewController = parentView!
                viewController.presentViewController(alertController, animated: true, completion: nil)
            }
        } else {
            var alertView = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: NSLocalizedString("dialog_ok", comment:""))
            alertView.show()
        }
    
    }
}
