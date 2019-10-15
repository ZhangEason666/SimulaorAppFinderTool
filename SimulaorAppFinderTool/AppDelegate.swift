//
//  AppDelegate.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/9.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // 给Info.plist里添加 LSUIElement 值设为 1 可以让App运行的时候不在dock栏出现
    //--> Application is agent (UIElement) : Boolen : YES
    
    fileprivate lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        statusItem.image = NSImage(named: NSImage.Name(rawValue: "BarIcon"))
        statusItem.highlightMode = true
        statusItem.isEnabled = true
        
        return statusItem
    }()
    
    /// 盛放的window
    fileprivate var mainWindow: NSWindow?
    /// aboutvc
    fileprivate var aboutVC: AboutViewController?
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusItem.action = #selector(presentApplicationMenuAction)
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDown)
    }
    ///  在当前 window 按键盘的接收事件
    fileprivate func keyDown(event: NSEvent) -> NSEvent {
        // 12 cmd+q  , 13 cmd+w
        if event.keyCode == 12 || event.keyCode == 13 {
            self.mainWindow?.close()
        }
        
        return event
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}






/// Menu拓展
extension AppDelegate {
    
    @objc fileprivate func presentApplicationMenuAction() {
        
        let menu = NSMenu()
        
        /// 3 添加子模块
        // 3.1 获取模拟器信息
        let simulators = self.activeSimulators()
        
        
        for (index, simulator) in simulators.enumerated() {
            
            //MARK: ----  模拟器个数  k_z_max_simulators
            if index > k_z_max_simulators {
                break
            }
            menu.addItem(NSMenuItem.separator())
            if let installedApplications = self.installedAppsOnSimulator(simulator: simulator) {
                let simulator_title = (simulator.name ?? "name") + (simulator.os ?? "os")
                /// title: 标题； acton: 执行的方法，如果nil 则title为灰色；keyEquivalent: 快捷键
                let simulatorMenuItem = NSMenuItem(title: simulator_title, action: nil, keyEquivalent: "")
                simulatorMenuItem.isEnabled = false
                menu.addItem(simulatorMenuItem)
                self.addApplications(applications: installedApplications, toMenu: menu)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        //MARK: 3.4 添加底部服务区的全局事件
        self.addServiceItemsToMenu(menu: menu)
        self.statusItem.popUpMenu(menu)
    }
    
    
    //MARK: --- 3.1  获取模拟器信息
    fileprivate func activeSimulators() -> [Simulator] {
        let simulatorPaths = CommonTools.simulatorPaths()
        
        var activeSimulators = [Simulator]()
        
        for path in simulatorPaths {
            let simulatorDetailsPath = (path as NSString).appending("device.plist")
            guard let properties = (NSDictionary(contentsOfFile: simulatorDetailsPath)) as? [String : AnyObject] else {
                continue
            }
            
            let simulator = Simulator.simulatorWithDictionary(properties: properties, path: path)
            
            activeSimulators.append(simulator)
            
        }
        
        
        // 3.2 最近使用的时间排序
        let tempSimulators = activeSimulators.sorted(by: { (sim1, sim2) -> Bool in
            let sim1_date = (sim1.date ?? Date())
            let sim2_date = (sim2.date ?? Date())
            let result = (sim1_date.compare(sim2_date))
            return (result.rawValue > 0)
            
        })
        
        
        
        return tempSimulators
    }
    
    //MARK: --- 3.2 获取安装的app
    func installedAppsOnSimulator(simulator: Simulator) -> [Application]? {
        guard let path = simulator.path else { return nil }
        
        let installedApplicationsDataPath = path + "data/Containers/Data/Application/"
        
        guard let installedApplications = CommonTools.getSortedFilesFromFolder(folderPath: installedApplicationsDataPath) else {
            return nil
        }
        
        var userApplications = [Application]()
        
        
        for appDict in installedApplications {
            let app = Application(dictionary: appDict, simulator: simulator)
            if app.isAppleApplication == false {
                userApplications.append(app)
            }
        }
        
        
        return userApplications
        
    }
    
    //MARK: --- 3.3 添加到menu上
    fileprivate func addApplications(applications: [Application], toMenu: NSMenu) {
        
        for application in applications {
            
            self.addApplication(application: application, toMenu: toMenu)
            
        }
        
        
    }
    //MARK: --- 3.3.1 添加到menu上
    fileprivate func addApplication(application: Application, toMenu: NSMenu) {
        let title = (application.bundleName ?? "App") + " (v" + (application.version ?? "1.0") + ")"
        
        if let applicationContentPath = application.contentPath {
            
            let item = NSMenuItem(title: title, action: #selector(openInWithModifier(sender:)), keyEquivalent:"")
            
            item.representedObject = applicationContentPath
            item.image = application.icon
            
            self.addSubMenusToItem(item: item, usingPath: applicationContentPath)
            
            toMenu.addItem(item)
        }
    }
    
    
    //MARK: 3.4 添加底部服务区的全局事件
    fileprivate func addServiceItemsToMenu(menu: NSMenu) {
        let startAtLogin = NSMenuItem(title: "开机启动", action: #selector(handleStartAtLogin(sender:)), keyEquivalent: "")
        let isStartAtLoginEnabled = CommonTools.startAtLoginEnabled()
        if (isStartAtLoginEnabled == true) {
            startAtLogin.state = .on
        } else {
            startAtLogin.state = .off
        }
        startAtLogin.representedObject = isStartAtLoginEnabled
        menu.addItem(startAtLogin)
        
        let clear_item = NSMenuItem(title: "清理Xcode缓存", action: #selector(clearXcodeCache(sender:)), keyEquivalent: "C")
        menu.addItem(clear_item)
        
        let quit_item = NSMenuItem(title: "退出", action: #selector(exitApp(sender:)), keyEquivalent: "Q")
        menu.addItem(quit_item)
        
    }
    
    /// 清理Xcode缓存
    @objc fileprivate func clearXcodeCache(sender: NSMenuItem) {
        let cachePath = "~/Library/Developer/Xcode"
        let openScriptString = String(format: "do shell script \"open %@\"", cachePath)
        if let openObject = NSAppleScript(source: openScriptString) {
            var error: NSDictionary?
            let descriptor = openObject.executeAndReturnError(&error)
            if 0 != descriptor.description.lengthOfBytes(using: .utf8) {
                debugPrint("打开成功")
            } else {
                debugPrint("打开失败")
            }
        }
        
    }
    
    fileprivate func dealClose() {
        /// 关闭window的
        self.mainWindow?.performClose(nil)
    }
    
    
    
    /// 退出登录
    @objc fileprivate func exitApp(sender: NSMenuItem) {
        
        NSApplication.shared.terminate(self)
    }
    
    
    /// 开机启动
    @objc fileprivate func handleStartAtLogin(sender: NSMenuItem) {
        
        if let isEnabled = sender.representedObject as? Bool {
            
            CommonTools().setStartAtLoginEnabled(enabled: !isEnabled)
            
            
            sender.representedObject = !isEnabled
            if isEnabled == true {
                sender.state = .on
            } else {
                sender.state = .off
            }
            
        }
    }
    
    
    
    
    /// 3.1.1.1 打开指定item
    @objc fileprivate func openInWithModifier(sender: NSMenuItem) {
        let event = NSApp.currentEvent
        
        if ((event?.modifierFlags) != nil) && (event?.modifierFlags == NSEvent.ModifierFlags.option) {
            self.openInTerminal(sender: sender)
        } else if ((event?.modifierFlags) != nil) && (event?.modifierFlags == NSEvent.ModifierFlags.control) {
            
        } else {
            self.openInFinder(sender: sender)
        }
        
        
    }
    
    /// 用终端代开
    @objc fileprivate func openInTerminal(sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        
        NSWorkspace.shared.openFile(path, withApplication: "Terminal")
        
    }
    
    @objc fileprivate func openIniTerm(sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        
        NSWorkspace.shared.openFile(path, withApplication: "iTerm")
        
    }
    
    /// 用Finder打开指定文件夹
    @objc fileprivate func openInFinder(sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        /// 打开Documents
        let docPath = path + "Documents"
        NSWorkspace.shared.openFile(docPath, withApplication: "Finder")
    }
    
    ///
    @objc fileprivate func copyToPasteboard(sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(path, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// 是否有模拟器在运行
    fileprivate func simulatorRunning() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(CGWindowListOption.excludeDesktopElements, kCGNullWindowID) as? [[String: AnyObject]] else {
            return false
        }
        
        for window in windows {
            guard let windowOwner = window[kCGWindowOwnerName as String] as? String,
                let windowName = window[kCGWindowName as String] as? String else {
                    return false
            }
            
            let ownercontains_Simulator = windowOwner.contains("Simulator")
            let name_contains_iOS_watchOS_tvOS = (windowName.contains("iOS") || windowName.contains("watchOS") || windowName.contains("tvOS"))
            
            if ownercontains_Simulator && name_contains_iOS_watchOS_tvOS {
                return true
            }
            
        }
        
        return false
        
    }
    
    /// 屏幕截图
    @objc fileprivate func takeScreenshot(sender: NSMenuItem) {
        
        CommonTools.takeScreenshot()
        
    }
    ///
    @objc fileprivate func resetApplication(sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        self.resetFolder(folder: "Documents", root: path)
        self.resetFolder(folder: "Library", root: path)
        self.resetFolder(folder: "tmp", root: path)
    }
    
    
    fileprivate func resetFolder(folder: String, root: String) {
        
        let path = (root as NSString).appendingPathComponent(folder)
        let fm = FileManager.default
        
        let en = fm.enumerator(atPath: path)
        
        while let file = en?.nextObject()  {
            if let file = file as? String {
                let path = (path as NSString).appendingPathComponent(file)
                
                try? fm.removeItem(atPath: path)
            }
        }
        
    }
    
    /// 3.1.2 继续添加item
    fileprivate func addSubMenusToItem(item: NSMenuItem, usingPath: String)  {
        var icon: NSImage?
        
        let subMenu = NSMenu()
        
        var hotkey: Int = 1
        
        let finder_item = NSMenuItem(title: "Finder", action: #selector(openInFinder(sender:)), keyEquivalent: "\(hotkey)")
        
        finder_item.representedObject = usingPath
        
        icon = NSWorkspace.shared.icon(forFile: FINDER_ICON_PATH)
        icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
        finder_item.image = icon
        
        subMenu.addItem(finder_item)
        
        hotkey = hotkey + 1
        
        let terminal_item = NSMenuItem(title: "Terminal", action: #selector(openInTerminal(sender:)), keyEquivalent: "\(hotkey)")
        terminal_item.representedObject = usingPath
        
        icon = NSWorkspace.shared.icon(forFile: TERMINAL_ICON_PATH)
        icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
        terminal_item.image = icon
        
        subMenu.addItem(terminal_item)
        
        hotkey = hotkey + 1
        
        guard let iTermBundleID = CFStringCreateWithCString(kCFAllocatorDefault, "com.googlecode.iterm2", CFStringBuiltInEncodings.UTF8.rawValue) else {
            return }
        if let _ = LSCopyApplicationURLsForBundleIdentifier(iTermBundleID, nil) {
            
            let iTerm = NSMenuItem(title: "iTerm", action: #selector(openIniTerm(sender:)), keyEquivalent: "\(hotkey)")
            iTerm.representedObject = usingPath
            
            icon = NSWorkspace.shared.icon(forFile: ITERM_ICON_PATH)
            
            icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
            iTerm.image = icon
            
            subMenu.addItem(iTerm)
            
            hotkey = hotkey + 1
            
        }
        
        subMenu.addItem(NSMenuItem.separator())
        
        let pasteboard_item = NSMenuItem(title: "Copy path to Clipboard", action: #selector(copyToPasteboard(sender:)), keyEquivalent: "\(hotkey)")
        
        pasteboard_item.representedObject = usingPath
        subMenu.addItem(pasteboard_item)
        
        hotkey = hotkey + 1
        
        if self.simulatorRunning() == true {
            let screenshot_item = NSMenuItem(title: "Copy path to Clipboard", action: #selector(takeScreenshot(sender:)), keyEquivalent: "\(hotkey)")
            
            screenshot_item.representedObject = usingPath
            subMenu.addItem(screenshot_item)
            
            hotkey = hotkey + 1
            
        }
        
        let resetApplication_item = NSMenuItem(title: "Reset application data", action: #selector(resetApplication(sender:)), keyEquivalent: "\(hotkey)")
        
        resetApplication_item.representedObject = usingPath
        subMenu.addItem(resetApplication_item)
        
        hotkey = hotkey + 1
        
        
        
        
        
        
    }
    
    
    
    /// 点击 dock 栏上的 icon 调起的动作
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        /// 将当前 app 的 window 放到最前面
        //        NSApp.activate(ignoringOtherApps: true)
        //        self.mainWindow?.makeKeyAndOrderFront(self)
        
        return true
    }
    
    
    
    
    
    
}




/// titlebar设置,并 window 代理
extension AppDelegate: NSWindowDelegate {
    /// 关闭Window的事件
    fileprivate func closeWindowAction() {
        if self.mainWindow != nil && self.aboutVC != nil {
            self.aboutVC = nil
            self.mainWindow = nil
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        /// false时 不能关闭
        return true
    }
    func windowWillClose(_ notification: Notification) {
        self.closeWindowAction()
        
        //        debugPrint("------->")
    }
    
    ///
    fileprivate func updateTitleBarOfWindow(window: NSWindow ,fullScreen: Bool) {
        let kTitlebarHeight: CGFloat = 24.0
//        let kFullScreenButtonYOrigin: CGFloat = 3.0
        let windowFrame = window.frame
        let titlebarContainerView = window.standardWindowButton(.closeButton)?.superview?.superview;
        
        if let titlebarContainerFrame = titlebarContainerView?.frame {
            var titlebarContainerFrame = titlebarContainerFrame
            titlebarContainerFrame.origin.y = windowFrame.size.height - kTitlebarHeight
            titlebarContainerFrame.size.height = CGFloat(kTitlebarHeight)
            titlebarContainerFrame.size.width = 80.0
            titlebarContainerView?.frame = titlebarContainerFrame
        }
        
        let buttonX:CGFloat = 6.0
        let closeButton = window.standardWindowButton(.closeButton)
        if let temp_rect = closeButton?.frame {
            var temp_rect = temp_rect
            if let size = (closeButton?.frame.size) {
                temp_rect.size = size
                temp_rect.origin = CGPoint(x: buttonX, y: round((kTitlebarHeight - temp_rect.height)/2.0))
                closeButton?.frame = temp_rect
            }
        }
        
        let minimizeButton = window.standardWindowButton(.miniaturizeButton)
        minimizeButton?.frame = CGRect.zero
        let zoomButton = window.standardWindowButton(.zoomButton)
        zoomButton?.frame = CGRect.zero
        
    }
    
}
