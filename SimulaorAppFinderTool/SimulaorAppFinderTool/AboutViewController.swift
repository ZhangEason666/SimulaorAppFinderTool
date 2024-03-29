//
//  AboutViewController.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/24.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    
    /// 介绍文本
    fileprivate lazy var introduce_textField: NSTextField? = {
        let introduce_textField = NSTextField()
        
        introduce_textField.stringValue = "打开最近使用的模拟器文件夹\n默认打开到Documents\n这是第一版"
        introduce_textField.isEditable = false
        introduce_textField.alignment = NSTextAlignment.center
        
        introduce_textField.frame = NSRect(x: 0, y: self.view.bounds.height/4, width: self.view.bounds.width, height: self.view.bounds.height/2)
        
        /// 边框线 是否有
        introduce_textField.isBordered = false
        
        return introduce_textField
    }()
    
    override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        if let fieldView = self.introduce_textField {
            self.view.addSubview(fieldView)
        }
    
        
        
    }
    
    
    deinit {
        debugPrint(#file, #function)
    }
    
    
    
    
    
    
    
}
