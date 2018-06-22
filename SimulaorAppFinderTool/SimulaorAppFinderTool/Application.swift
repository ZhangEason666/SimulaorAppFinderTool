//
//  Application.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/9.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

class Application: NSObject {

    
    public class func z_applicationWithDictionary(dictionary: [String: AnyObject], simulator: Simulator) -> Application {
        
        let a_appliation = Application(dictionary: dictionary, simulator: simulator)
        
        
        
        return a_appliation
    }
    
    convenience init(dictionary: [String: AnyObject], simulator: Simulator) {
        self.init()
        
        
        self.uuid = dictionary[KEY_FILE] as? String
        
        self.properties = self.a_getApplicationPropertiesByUUID(uuid: self.uuid!, rootPath: simulator.path!)
        
        self.bundleIdentifier = self.properties?["MCMMetadataIdentifier"] as? String
        self.isAppleApplication = self.bundleIdentifier?.hasPrefix("com.apple")
        
        
        self.a_buildMetadataForBundle(bundleId: self.bundleIdentifier!, rootPath: simulator.path!)
    }
    
    
    fileprivate func a_buildMetadataForBundle(bundleId: String, rootPath: String) {
        
        let a_installedApplicationsBundlePath = rootPath + "data/Containers/Bundle/Application/"
        
        
        let a_installedApplicationsBundle = CommonTools.z_getSortedFilesFromFolder(folderPath: a_installedApplicationsBundlePath)
        
       
        self.a_processBundles(bundles: a_installedApplicationsBundle!, rootPath: rootPath, bundleId: bundleId) {[weak self] (applicationRootBundlePath) in
            
            let applicationFolderName = CommonTools.z_getApplicationFolderFromPath(folderPath: applicationRootBundlePath)
            
            let applicationFolderPath = applicationRootBundlePath + applicationFolderName
            
            let applicationPlistPath = applicationFolderPath + "/Info.plist"
            
            
            guard let applicationPlist = NSDictionary(contentsOfFile: applicationPlistPath) as? [String: AnyObject] else {
                assertionFailure("没拿到")
                return
            }
            
            let applicationVersion = applicationPlist["CFBundleShortVersionString"] as? String
            
            var applicationBundleName = applicationPlist["CFBundleName"] as? NSString
            
            
            if applicationBundleName?.length == 0 {
                applicationBundleName = applicationPlist["CFBundleDisplayName"] as? NSString
            }
            
            let a_icon = self?.a_getIconForApplicationWithPlist(applicationPlist: applicationPlist, folderPath: applicationFolderPath)
            
            self?.bundleName = applicationBundleName! as String
            self?.version = applicationVersion
            self?.icon = a_icon
            
        }
    }
    
    
    fileprivate func a_getIconForApplicationWithPlist(applicationPlist: [String: AnyObject], folderPath: String) -> NSImage {
        
        var iconPath = ""
        var applicationIcon = applicationPlist["CFBundleIconFile"] as? String
        
        let fileManager = FileManager.default
        
        if applicationIcon != nil {
            iconPath = folderPath + applicationIcon!

        } else {
            var applicationIcons = applicationPlist["CFBundleIcons"] as? [String: AnyObject]
            
            
            var postfix = ""
            
            if applicationIcons?.isEmpty == true {
                applicationIcons = applicationPlist["CFBundleIcons~ipad"] as? [String: AnyObject]
                postfix = "~ipad"
            }
            
            let applicationPrimaryIcons = applicationIcons?["CFBundlePrimaryIcon"] as? [String: AnyObject]
            
            if applicationPrimaryIcons?.isEmpty == false {
                
                let iconFiles = (applicationPrimaryIcons!["CFBundleIconFiles"] as? [String])
                
                if iconFiles?.isEmpty == false {
                   applicationIcon = iconFiles?.last
                   iconPath = folderPath + "/" + applicationIcon! + postfix + ".png"
                    
                    if fileManager.fileExists(atPath: iconPath) == false {
                    iconPath = folderPath + "/" + applicationIcon! + "@2x" + postfix + ".png"
                    }
                    
                    
                } else {
                    
                    iconPath = ""
                }
            } else {
                
                iconPath = ""
            }
            
        }
        
        if fileManager.fileExists(atPath: iconPath) == false {
            
            iconPath = ""
        }
        
        
        var a_icon: NSImage?
        if iconPath == "" {
            a_icon = #imageLiteral(resourceName: "EmptyItemIcon")
        } else {
            
            a_icon = NSImage(contentsOfFile: iconPath)
        }
        
        
        a_icon = a_icon?.z_roundCorners(a_image: a_icon!, toSize: NSSize(width: 24, height: 24))
        
        return a_icon!
    }
    
    
    
    func a_processBundles(bundles: [[String: AnyObject]], rootPath: String, bundleId: String, finishBlock:(_ applicationRootBundlePath: String)->()) {
        
        for a_dict in bundles {
            let appBundleUUID = a_dict[KEY_FILE] as! String
            let applicationRootBundlePath = rootPath + "data/Containers/Bundle/Application/" + appBundleUUID + "/"
            
            let applicationBundlePropertiesPath = applicationRootBundlePath + ".com.apple.mobile_container_manager.metadata.plist"
            
            let applicationBundleProperties = NSDictionary(contentsOfFile: applicationBundlePropertiesPath)
            
            
            let bundleIdentifier = applicationBundleProperties!["MCMMetadataIdentifier"] as! String
            
            if bundleIdentifier == bundleId {
                finishBlock(applicationRootBundlePath)
                break
            }
        }
        
    }
    
    
    
    
    fileprivate func a_getApplicationPropertiesByUUID(uuid: String, rootPath: String) -> [String: AnyObject] {
        
        self.contentPath = self.a_applicationRootPathByUUID(uuid: uuid, rootPath: rootPath)
        
        
        let a_applicationDataPropertiesPath = self.contentPath! + ".com.apple.mobile_container_manager.metadata.plist"
        
        let a_result = NSDictionary(contentsOfFile: a_applicationDataPropertiesPath)
        
        
        return (a_result as! [String : AnyObject])
        
    }
    
    fileprivate func a_applicationRootPathByUUID(uuid: String, rootPath: String) -> String {
        return rootPath + "data/Containers/Data/Application/" + uuid + "/";
    }
    
    
    
    
    fileprivate var properties: [String: AnyObject]?
    private(set) var uuid: String?
    private(set) var bundleIdentifier: String?
    private(set) var bundleName: String?
    private(set) var version: String?
    private(set) var icon: NSImage?
    private(set) var contentPath: String?
    private(set) var isAppleApplication: Bool?
    
    
    
    
    
    
    
}
