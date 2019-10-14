//
//  Simulator.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/9.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

/// 最多展示几个模拟器
let k_z_max_simulators = 10//5

class Simulator: NSObject {

    fileprivate var properties: [String: AnyObject]?
    /// 只读
    private(set) var name: String?
    private(set) var os: String?
    private(set) var path: String?
    private(set) var date: Date?
    
   
    
    public class func simulatorWithDictionary(properties: [String: AnyObject], path: String) -> Simulator {
        let simulator = Simulator(properties: properties, path: path)
        
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            return simulator
        }
        
        guard let date = attrs[FileAttributeKey.modificationDate] as? Date else {
            return simulator
        }
        simulator.date = date
        
        
        return simulator
    }
    
    
    
    
    convenience init(properties: [String: AnyObject]?, path: String) {
        self.init()
        
        guard let properties = properties else { return }
        self.properties = properties
        
        self.name = self.set_name()
        self.os = self.set_os()
        self.path = path
    }
    
    
    //MARK: -- 设置name、os
    fileprivate func set_name() -> String {
        let name = (self.properties!["name"] as! String)
        return name
    }
    
    fileprivate func set_os() -> String {
        var os_runtime = (self.properties!["runtime"] as! NSString).replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime", with: "")
        
        os_runtime = os_runtime.replacingOccurrences(of: "OS-", with: "OS")
        os_runtime = os_runtime.replacingOccurrences(of: "-", with: ".")
        
        var temp_os = (os_runtime as NSString).replacingCharacters(in: NSMakeRange(0, 1), with: " ")
        if (self.name?.contains(temp_os)) == true {
            temp_os = ""
        }
        
        return temp_os
        
    }

    
    
    
    
    
    
    
    
    
    
    
}
