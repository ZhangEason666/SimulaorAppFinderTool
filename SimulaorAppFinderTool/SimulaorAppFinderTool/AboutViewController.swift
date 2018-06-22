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
    fileprivate lazy var a_introduce_textField: NSTextField? = {
        let a_introduce_textField = NSTextField()
        
        a_introduce_textField.stringValue = "打开最近使用的模拟器文件夹\n默认打开到Documents\n这是第一版"
        a_introduce_textField.isEditable = false
        a_introduce_textField.alignment = NSTextAlignment.center
        
        a_introduce_textField.frame = NSRect(x: 0, y: self.view.bounds.height/4, width: self.view.bounds.width, height: self.view.bounds.height/2)
        
        /// 边框线 是否有
        a_introduce_textField.isBordered = false
        
        return a_introduce_textField
    }()
    
    override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.view.addSubview(self.a_introduce_textField!)
        
    
        
        
    }
    
    
    deinit {
        debugPrint(#file, #function)
    }
    
    
    
    
    
    
    
}
