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
    
    fileprivate func getLastLoginItemInList() -> LSSharedFileListItem! {
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
    public func setStartAtLoginEnabled(enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        var url = NSURL(fileURLWithPath: appPath)
        /// 多种桥接内存问题  http://nshipster.cn/unmanaged/
      let loginIs = LSSharedFileListCreate(kCFAllocatorNull, kLSSharedFileListSessionLoginItems.takeUnretainedValue(), nil)
        
        let loginItems = loginIs?.takeUnretainedValue()
//        loginItems?.release()
        
        if enabled == true {
           let itemlast = self.getLastLoginItemInList()// kLSSharedFileListItemLast.takeUnretainedValue()
           let result = LSSharedFileListInsertItemURL(loginItems, itemlast, nil, nil, url, nil, nil)
            
            result?.release()
            
            
        } else {
            
            var seedValue: UInt32 = 0
            let loginItemsArrays = LSSharedFileListCopySnapshot(loginItems , &seedValue).takeUnretainedValue()
            let loginItemsArray = loginItemsArrays as! [LSSharedFileListItem]
        
            for item in loginItemsArray {
                if let uuurl = LSSharedFileListItemCopyResolvedURL(item, 0, nil) {
                    url = uuurl.takeUnretainedValue()
                    let urlPath = (url as NSURL).path
                    if urlPath?.compare(appPath) == ComparisonResult.orderedSame {
                        LSSharedFileListItemRemove(loginItems, item)
                    }
                }
            }
        }
        
    }
    
    /// 设置开机启动
    public class func startAtLoginEnabled() -> Bool {
    
        let appPath = Bundle.main.bundlePath
        
        var url = NSURL(fileURLWithPath: appPath)
        
        guard let loginIs = LSSharedFileListCreate(nil, (kLSSharedFileListSessionLoginItems.takeUnretainedValue()) , nil) else {
            return false
        }
        var result = false
        
        let loginItems = loginIs.takeUnretainedValue()
        
        var seedValue: UInt32 = 0
        let loginItemsArrays = LSSharedFileListCopySnapshot(loginItems , &seedValue).takeUnretainedValue()
        
        let loginItemsArray = loginItemsArrays as! [LSSharedFileListItem]
        
        for item in loginItemsArray {
            if let uuurl = LSSharedFileListItemCopyResolvedURL(item, 0, nil) {
                url = uuurl.takeUnretainedValue()
                let urlPath = (url as NSURL).path
                if urlPath?.compare(appPath) == ComparisonResult.orderedSame {
                    result = true
                }
            }
        }
        
        return result
    }
    
    /// 存储路径
    public class func homeDirectory() -> String {
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
    public class func simulatorPaths() -> [String] {
        var simulatorPaths = [String]()
        /// plist存储位置
         let simulatorPropertiesPath = homeDirectory() + "/Library/Preferences/com.apple.iphonesimulator.plist"
        
        guard let simulatorPropertiesDict = NSDictionary(contentsOfFile: simulatorPropertiesPath),
            let uuid = simulatorPropertiesDict["CurrentDeviceUDID"] as? String else {
                return []
        }
        guard let devicePreferences = simulatorPropertiesDict["DevicePreferences"] as? [String: AnyObject]
            else {
                simulatorPaths.append(simulatorRootPathByUUID(uuid: uuid))
                return simulatorPaths
        }
       
        /// 当前最新的APP放最上边
        let current_uuidStr = simulatorRootPathByUUID(uuid: uuid)
        simulatorPaths.append(current_uuidStr)
        
        for uuidStr in devicePreferences.keys {
            let this_uuidStr = simulatorRootPathByUUID(uuid: uuidStr)
            if this_uuidStr == current_uuidStr {
                continue
            }
            simulatorPaths.append(this_uuidStr)
        }
        
        
        return simulatorPaths
    }
    
    
    /// 单个app在磁盘中的位置
    public class func simulatorRootPathByUUID(uuid: String) -> String {
        
        let fullpath = homeDirectory() + "/Library/Developer/CoreSimulator/Devices/" + uuid + "/"
        return fullpath
        
    }
    
    
    
    /// 给当前目录下文件排序
    public class func getSortedFilesFromFolder(folderPath: String) -> [[String : AnyObject]]? {
        guard let filesArray = try? FileManager.default.contentsOfDirectory(atPath: folderPath) else {
            return nil
        }
        
        /// 按创建时间排序
        var filesAndProperties = [[String: AnyObject]]()
        
        for file in filesArray {
            if file != ".DS_Store" {
                let filePath = (folderPath as NSString).appendingPathComponent(file)
                guard let properties = try? FileManager.default.attributesOfItem(atPath: filePath) else {
                    continue
                }
                let modificationDate = properties[FileAttributeKey.modificationDate] as! Date
                
                let fileType = properties[FileAttributeKey.type]
                let dict = [KEY_FILE: file,
                              KEY_MODIFICATION_DATE: modificationDate,
                              KEY_FILE_TYPE: fileType]  as [String : AnyObject]
                filesAndProperties.append(dict)
            }
        }
        
        let sortedFiles = filesAndProperties.sorted(by: { (path1, path2) -> Bool in
            let p1_date = ((path1["modificationDate"] as? Date) ?? Date()) as Date
            let p2_date = ((path2["modificationDate"] as? Date) ?? Date()) as Date
            let comp = p1_date.compare(p2_date)
//            if comp == ComparisonResult.orderedDescending {
//                comp = ComparisonResult.orderedAscending
//            } else if comp == ComparisonResult.orderedAscending {
//                comp = ComparisonResult.orderedDescending
//            }
            return (comp.rawValue > 0)
        })
        
        
        return sortedFiles
    }
    
    /// 获取当前目录下的Application name对象
    public class func getApplicationFolderFromPath(folderPath: String) -> String {
        
        guard let filesArrays = try? FileManager.default.contentsOfDirectory(atPath: folderPath) else {
            return ""
        }
    let predicate = NSPredicate(format: "SELF EndsWith '.app'")
        
        let filesArray = (filesArrays as NSArray).filtered(using: predicate)

        let resultStr = (filesArray.first ?? "") as! String
        return resultStr
        
    }
    
    
    
    /// 屏幕截图
    public class func takeScreenshot() {
        
        guard let windows = CGWindowListCopyWindowInfo(CGWindowListOption.excludeDesktopElements, kCGNullWindowID) as? [[String: AnyObject]] else {
            return
        }
        
        for window in windows {
            guard let windowOwner = window[kCGWindowOwnerName as String] as? String,
                let windowName = window[kCGWindowName as String] as? String else {
                    return
            }
            
            let ownercontains_Simulator = windowOwner.contains("Simulator")
            let name_contains_iOS_watchOS_tvOS = (windowName.contains("iOS") || windowName.contains("watchOS") || windowName.contains("tvOS"))
            
            if ownercontains_Simulator && name_contains_iOS_watchOS_tvOS {
                
                let windowID = window[kCGWindowNumber as String] as? CGWindowID
                let dateComponets = "yyyyMMdd_ HHmmss_SSSS"
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = dateComponets
                
                let date = Date()
                
                let dateString = dateFormatter.string(from: date)
                
                let screenshotPath = CommonTools.homeDirectory() + "/Desktop/Screen shot at" + dateString + ".png"
                
                let windBoundsDict = window[kCGWindowBounds as String] as! CFDictionary
                let bounds = CGRect(dictionaryRepresentation: windBoundsDict)
                
                let image = CGWindowListCreateImage(bounds!, CGWindowListOption.optionIncludingWindow, windowID!, CGWindowImageOption.bestResolution)
                
                let bitMap = NSBitmapImageRep(cgImage: image!)
                
                let img_data = bitMap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])! as NSData
                
                img_data.write(toFile: screenshotPath, atomically: true)
                
            }
        }
        
        
        
    }
    
    
    
    
    
    
    
    
}
