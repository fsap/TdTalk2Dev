//
//  LodingView.swift
//  tdtalk2dev
//
//  Created by Fujiwara on 2015/08/22.
//  Copyright (c) 2015年 fsap. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

class LoadingView: UIView {
    
    private var activityIndicator: UIActivityIndicatorView
    private var sound_source: dispatch_source_t?

    
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView()
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(parentView: UIView) {
        self.init(frame: parentView.frame)
        
        activityIndicator.frame = CGRectMake(0, 0, 50, 50)
        activityIndicator.center = parentView.center
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        parentView.addSubview(activityIndicator)
    }
    
    func start() {
        activityIndicator.startAnimating()
        
        /*
        サウンド再生
        */
        let queue = dispatch_queue_create("book_loading", nil)
        sound_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        // キャンセルハンドラ
        dispatch_source_set_cancel_handler(sound_source!, { () -> Void in
            if self.sound_source != nil {
                self.sound_source = nil;
            }
        })
        
        // タイマー
        dispatch_source_set_timer(
            sound_source!,
            dispatch_time(DISPATCH_TIME_NOW, (Int64)(2 * NSEC_PER_SEC)),
            2 * NSEC_PER_SEC,
            0)
        
        dispatch_source_set_event_handler(sound_source!, { () -> Void in
            // システムサウンドを鳴らす
            LogM("sound...")
            AudioServicesPlaySystemSound(1104)
        })
        
        dispatch_resume(sound_source!);
        
    }
    
    func stop() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        
        if sound_source != nil {
            dispatch_source_cancel(sound_source!)
        }
    }
}