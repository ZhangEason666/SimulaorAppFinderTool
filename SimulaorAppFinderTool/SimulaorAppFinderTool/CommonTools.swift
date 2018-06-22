//
//  CommonTools.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/9.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

let KEY_FILE = "file"
let KEY_MODIFICATION_DATE = "modificationDate"
let KEY_FILE_TYPE = "fileType"
let ACTION_ICON_SIZE: CGFloat = 16


let FINDER_ICON_PATH = "/System/Library/CoreServices/Finder.app"
let TERMINAL_ICON_PATH = "/Applications/Utilities/Terminal.app"
let ITERM_ICON_PATH = "/Applications/iTerm.app"
let CMDONE_ICON_PATH = "/Applications/Commander One.app"


class CommonTools: NSObject {
    
    fileprivate func a_getLastLoginItemInList() -> LSSharedFileListItem! {
        ///
        let loginUtemsList: LSSharedFileList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeUnretainedValue(), nil).takeUnretainedValue()
        let loginItems: NSArray = LSSharedFileListCopySnapshot(loginUtemsList, nil).takeUnretainedValue()
        
        if loginItems.count > 0 {
            let lastLoginItem = loginItems.lastObject as! LSSharedFileListItem
            
            return lastLoginItem
        }
        return kLSSharedFileListItemBeforeFirst.takeUnretainedValue()
    }

    /// 设置开机启动
    public func z_setStartAtLoginEnabled(enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        var url = NSURL(fileURLWithPath: appPath)
        /// 多种桥接内存问题  http://nshipster.cn/unmanaged/
      let a_loginItems = LSSharedFileListCreate(kCFAllocatorNull, kLSSharedFileListSessionLoginItems.takeUnretainedValue(), nil)
        
        let loginItems = a_loginItems?.takeUnretainedValue()
//        a_loginItems?.release()
        
        if enabled == true {
           let a_itemlast = self.a_getLastLoginItemInList()// kLSSharedFileListItemLast.takeUnretainedValue()
           let a_result = LSSharedFileListInsertItemURL(loginItems, a_itemlast, nil, nil, url, nil, nil)
            
            a_result?.release()
            
            
        } else {
            
            var seedValue: UInt32 = 0
            let a_loginItemsArray = LSSharedFileListCopySnapshot(loginItems , &seedValue).takeUnretainedValue()
            let loginItemsArray = a_loginItemsArray as! [LSSharedFileListItem]
        
            for a_item in loginItemsArray {
                url = LSSharedFileListItemCopyResolvedURL(a_item, 0, nil).takeUnretainedValue()
                
                let urlPath = (url as NSURL).path
                
                if urlPath?.compare(appPath) == ComparisonResult.orderedSame {
                    LSSharedFileListItemRemove(loginItems, a_item)
                }
                
            }
        }
        
    }
    
    /// 设置开机启动
    public class func z_startAtLoginEnabled() -> Bool {
    
        let appPath = Bundle.main.bundlePath
        
        var url = NSURL(fileURLWithPath: appPath)
        
        //FIXME: -- 这里只能取到 iTunesHelper.app ??
        guard let a_loginItems = LSSharedFileListCreate(nil, (kLSSharedFileListSessionLoginItems.takeUnretainedValue()) , nil) else {
            return false
        }
        var a_result = false
        
        let loginItems = a_loginItems.takeUnretainedValue()
        
        var seedValue: UInt32 = 0
        let a_loginItemsArray = LSSharedFileListCopySnapshot(loginItems , &seedValue).takeUnretainedValue()
        
        let loginItemsArray = a_loginItemsArray as! [LSSharedFileListItem]
        
        for a_item in loginItemsArray {
            url = LSSharedFileListItemCopyResolvedURL(a_item, 0, nil).takeUnretainedValue()
            
            let urlPath = (url as NSURL).path
            
            if urlPath?.compare(appPath) == ComparisonResult.orderedSame {
                a_result = true
            }
            
        }
        
        return a_result
    }
    
    /// 存储路径
    public class func z_homeDirectory() -> String {
        /// 1、需要在 .entitlements 里添加
        // App Sandbox :Boolen : YES
        // com.apple.security.files.user-selected.read-only : Boolen : YES
        // com.apple.security.temporary-exception.files.home-relative-path.read-only
        // : Array: Item 0 : String: /Libiary/
        
        /// 2、不需要开启 Sandbox
        /// App Sandbox : Boolen: NO

        /// 如果开启获取的就是  /Users/username/Library/Containers/identifierID/Data
        /// 开启了权限获取的就是 /Users/username/
        return NSHomeDirectory()
    }
   
    /// 模拟器存储位置路径数组
    public class func z_simulatorPaths() -> [String] {
        var a_simulatorPaths = [String]()
        /// plist存储位置
         let a_simulatorPropertiesPath = z_homeDirectory() + "/Library/Preferences/com.apple.iphonesimulator.plist"
        
        guard let a_simulatorPropertiesDict = NSDictionary(contentsOfFile: a_simulatorPropertiesPath),
            let a_uuid = a_simulatorPropertiesDict["CurrentDeviceUDID"] as? String else {
                return []
        }
        guard let a_devicePreferences = a_simulatorPropertiesDict["DevicePreferences"] as? [String: AnyObject]
            else {
                a_simulatorPaths.append(z_simulatorRootPathByUUID(uuid: a_uuid))
                return a_simulatorPaths
        }
       
        /// 当前最新的APP放最上边
        let a_current_uuidStr = z_simulatorRootPathByUUID(uuid: a_uuid)
        a_simulatorPaths.append(a_current_uuidStr)
        
        for a_uuidStr in a_devicePreferences.keys {
            let a_this_uuidStr = z_simulatorRootPathByUUID(uuid: a_uuidStr)
            if a_this_uuidStr == a_current_uuidStr {
                continue
            }
            a_simulatorPaths.append(a_this_uuidStr)
        }
        
        
        return a_simulatorPaths
    }
    
    
    /// 单个app在磁盘中的位置
    public class func z_simulatorRootPathByUUID(uuid: String) -> String {
        
        let a_fullpath = z_homeDirectory() + "/Library/Developer/CoreSimulator/Devices/" + uuid + "/"
        return a_fullpath
        
    }
    
    
    
    /// 给当前目录下文件排序
    public class func z_getSortedFilesFromFolder(folderPath: String) -> [[String : AnyObject]]? {
        guard let a_filesArray = try? FileManager.default.contentsOfDirectory(atPath: folderPath) else {
            return nil
        }
        
        /// 按创建时间排序
        var a_filesAndProperties = [[String: AnyObject]]()
        
        for a_file in a_filesArray {
            if a_file != ".DS_Store" {
                let a_filePath = (folderPath as NSString).appendingPathComponent(a_file)
                guard let a_properties = try? FileManager.default.attributesOfItem(atPath: a_filePath) else {
                    continue
                }
                let a_modificationDate = a_properties[FileAttributeKey.modificationDate] as! Date
                
                let a_fileType = a_properties[FileAttributeKey.type]
                let a_dict = [KEY_FILE: a_file,
                              KEY_MODIFICATION_DATE: a_modificationDate,
                              KEY_FILE_TYPE: a_fileType]  as [String : AnyObject]
                a_filesAndProperties.append(a_dict)
            }
        }
        
        let a_sortedFiles = a_filesAndProperties.sorted(by: { (path1, path2) -> Bool in
            let a_p1_date = ((path1["modificationDate"] as? Date) ?? Date()) as Date
            let a_p2_date = ((path2["modificationDate"] as? Date) ?? Date()) as Date
            let a_comp = a_p1_date.compare(a_p2_date)
//            if a_comp == ComparisonResult.orderedDescending {
//                a_comp = ComparisonResult.orderedAscending
//            } else if a_comp == ComparisonResult.orderedAscending {
//                a_comp = ComparisonResult.orderedDescending
//            }
            return (a_comp.rawValue > 0)
        })
        
        
        return a_sortedFiles
    }
    
    /// 获取当前目录下的Application name对象
    public class func z_getApplicationFolderFromPath(folderPath: String) -> String {
        
        guard let a_filesArray = try? FileManager.default.contentsOfDirectory(atPath: folderPath) else {
            return ""
        }
    let a_predicate = NSPredicate(format: "SELF EndsWith '.app'")
        
        let filesArray = (a_filesArray as NSArray).filtered(using: a_predicate)

        let a_resultStr = (filesArray.first ?? "") as! String
        return a_resultStr
        
    }
    
    
    
    /// 屏幕截图
    public class func z_takeScreenshot() {
        
        guard let windows = CGWindowListCopyWindowInfo(CGWindowListOption.excludeDesktopElements, kCGNullWindowID) as? [[String: AnyObject]] else {
            return
        }
        
        for a_window in windows {
            guard let windowOwner = a_window[kCGWindowOwnerName as String] as? String,
                let windowName = a_window[kCGWindowName as String] as? String else {
                    return
            }
            
            let a_ownercontains_Simulator = windowOwner.contains("Simulator")
            let a_name_contains_iOS_watchOS_tvOS = (windowName.contains("iOS") || windowName.contains("watchOS") || windowName.contains("tvOS"))
            
            if a_ownercontains_Simulator && a_name_contains_iOS_watchOS_tvOS {
                
                let windowID = a_window[kCGWindowNumber as String] as? CGWindowID
                let dateComponets = "yyyyMMdd_ HHmmss_SSSS"
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = dateComponets
                
                let date = Date()
                
                let dateString = dateFormatter.string(from: date)
                
                let screenshotPath = CommonTools.z_homeDirectory() + "/Desktop/Screen shot at" + dateString + ".png"
                
                let a_windBoundsDict = a_window[kCGWindowBounds as String] as! CFDictionary
                let a_bounds = CGRect(dictionaryRepresentation: a_windBoundsDict)
                
                let a_image = CGWindowListCreateImage(a_bounds!, CGWindowListOption.optionIncludingWindow, windowID!, CGWindowImageOption.bestResolution)
                
                let a_bitMap = NSBitmapImageRep(cgImage: a_image!)
                
                let a_img_data = a_bitMap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])! as NSData
                
                a_img_data.write(toFile: screenshotPath, atomically: true)
                
            }
        }
        
        
        
    }
    
    
    
    
    
    
    
    
}
