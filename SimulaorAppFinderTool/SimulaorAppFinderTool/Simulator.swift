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
    
   
    
    public class func z_simulatorWithDictionary(properties: [String: AnyObject], path: String) -> Simulator {
        let a_simulator = Simulator(properties: properties, path: path)
        
        guard let a_attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            return a_simulator
        }
        
        guard let a_date = a_attrs[FileAttributeKey.modificationDate] as? Date else {
            return a_simulator
        }
        a_simulator.date = a_date
        
        
        return a_simulator
    }
    
    
    
    
    convenience init(properties: [String: AnyObject]?, path: String) {
        self.init()
        
        guard let properties = properties else { return }
        self.properties = properties
        
        self.name = self.a_set_name()
        self.os = self.a_set_os()
        self.path = path
    }
    
    
    //MARK: -- 设置name、os
    fileprivate func a_set_name() -> String {
        let a_name = (self.properties!["name"] as! String)
        return a_name
    }
    
    fileprivate func a_set_os() -> String {
        var a_os_runtime = (self.properties!["runtime"] as! NSString).replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime", with: "")
        
        a_os_runtime = a_os_runtime.replacingOccurrences(of: "OS-", with: "OS")
        a_os_runtime = a_os_runtime.replacingOccurrences(of: "-", with: ".")
        
        var a_temp_os = (a_os_runtime as NSString).replacingCharacters(in: NSMakeRange(0, 1), with: " ")
        if (self.name?.contains(a_temp_os)) == true {
            a_temp_os = ""
        }
        
        return a_temp_os
        
    }

    
    
    
    
    
    
    
    
    
    
    
}
