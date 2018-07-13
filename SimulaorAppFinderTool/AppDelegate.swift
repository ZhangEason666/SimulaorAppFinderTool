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
    
    fileprivate lazy var a_statusItem: NSStatusItem = {
        let a_statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        a_statusItem.image = NSImage(named: NSImage.Name(rawValue: "BarIcon"))
        a_statusItem.highlightMode = true
        a_statusItem.isEnabled = true
        
        return a_statusItem
    }()
    
    /// 盛放的window
    fileprivate var mainWindow: NSWindow?
    /// aboutvc
    fileprivate var a_aboutVC: AboutViewController?
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.a_statusItem.action = #selector(a_presentApplicationMenuAction)
        
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
    
    @objc fileprivate func a_presentApplicationMenuAction() {
        
        let a_menu = NSMenu()
        
        /// 3 添加子模块
        // 3.1 获取模拟器信息
        let a_simulators = self.a_activeSimulators()
        
        
        for (a_index, a_simulator) in a_simulators.enumerated() {
            
            //MARK: ----  模拟器个数  k_z_max_simulators
            if a_index > k_z_max_simulators {
                break
            }
            a_menu.addItem(NSMenuItem.separator())
            if let a_installedApplications = self.a_installedAppsOnSimulator(a_simulator: a_simulator) {
                let a_simulator_title = (a_simulator.name ?? "name") + (a_simulator.os ?? "os")
                /// title: 标题； acton: 执行的方法，如果nil 则title为灰色；keyEquivalent: 快捷键
                let a_simulatorMenuItem = NSMenuItem(title: a_simulator_title, action: nil, keyEquivalent: "")
                a_simulatorMenuItem.isEnabled = false
                a_menu.addItem(a_simulatorMenuItem)
                self.a_addApplications(applications: a_installedApplications, toMenu: a_menu)
            }
        }
        
        a_menu.addItem(NSMenuItem.separator())
        //MARK: 3.4 添加底部服务区的全局事件
        self.a_addServiceItemsToMenu(menu: a_menu)
        self.a_statusItem.popUpMenu(a_menu)
    }
    
    
    //MARK: --- 3.1  获取模拟器信息
    fileprivate func a_activeSimulators() -> [Simulator] {
        let a_simulatorPaths = CommonTools.z_simulatorPaths()
        
        var a_activeSimulators = [Simulator]()
        
        for a_path in a_simulatorPaths {
            let a_simulatorDetailsPath = (a_path as NSString).appending("device.plist")
            guard let a_properties = (NSDictionary(contentsOfFile: a_simulatorDetailsPath)) as? [String : AnyObject] else {
                continue
            }
            
            let a_simulator = Simulator.z_simulatorWithDictionary(properties: a_properties, path: a_path)
            
            a_activeSimulators.append(a_simulator)
            
        }
        
        
        // 3.2 最近使用的时间排序
        let a_tempSimulators = a_activeSimulators.sorted(by: { (sim1, sim2) -> Bool in
            let a_sim1_date = (sim1.date ?? Date())
            let a_sim2_date = (sim2.date ?? Date())
            let a_result = (a_sim1_date.compare(a_sim2_date))
            return (a_result.rawValue > 0)
            
        })
        
        
        
        return a_tempSimulators
    }
    
    //MARK: --- 3.2 获取安装的app
    func a_installedAppsOnSimulator(a_simulator: Simulator) -> [Application]? {
        guard let a_path = a_simulator.path else { return nil }
        
        let a_installedApplicationsDataPath = a_path + "data/Containers/Data/Application/"
        
        guard let a_installedApplications = CommonTools.z_getSortedFilesFromFolder(folderPath: a_installedApplicationsDataPath) else {
            return nil
        }
        
        var a_userApplications = [Application]()
        
        
        for a_appDict in a_installedApplications {
            let a_app = Application(dictionary: a_appDict, simulator: a_simulator)
            if a_app.isAppleApplication == false {
                a_userApplications.append(a_app)
            }
        }
        
        
        return a_userApplications
        
    }
    
    //MARK: --- 3.3 添加到menu上
    fileprivate func a_addApplications(applications: [Application], toMenu: NSMenu) {
        
        for a_application in applications {
            
            self.a_addApplication(application: a_application, toMenu: toMenu)
            
        }
        
        
    }
    //MARK: --- 3.3.1 添加到menu上
    fileprivate func a_addApplication(application: Application, toMenu: NSMenu) {
        let a_title = (application.bundleName ?? "App") + " (v" + (application.version ?? "1.0") + ")"
        
        if let applicationContentPath = application.contentPath {
            
            let a_item = NSMenuItem(title: a_title, action: #selector(a_openInWithModifier(sender:)), keyEquivalent:"")
            
            a_item.representedObject = applicationContentPath
            a_item.image = application.icon
            
            self.a_addSubMenusToItem(a_item: a_item, usingPath: applicationContentPath)
            
            toMenu.addItem(a_item)
        }
    }
    
    
    //MARK: 3.4 添加底部服务区的全局事件
    fileprivate func a_addServiceItemsToMenu(menu: NSMenu) {
        let startAtLogin = NSMenuItem(title: "开机启动", action: #selector(a_handleStartAtLogin(sender:)), keyEquivalent: "")
        let isStartAtLoginEnabled = CommonTools.z_startAtLoginEnabled()
        if (isStartAtLoginEnabled == true) {
            startAtLogin.state = .on
        } else {
            startAtLogin.state = .off
        }
        startAtLogin.representedObject = isStartAtLoginEnabled
        menu.addItem(startAtLogin)
        var a_version_str = ""
        if let version_str = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            
        }
        var appVersion_str = "关于 "
        if let a_locaized = NSRunningApplication.current.localizedName {
            appVersion_str = "\(appVersion_str)  \(a_version_str)  \(a_version_str) "
        }
        
        let about_item = NSMenuItem(title: appVersion_str, action: #selector(a_aboutApp(sender:)), keyEquivalent: "I")
        menu.addItem(about_item)
        
        let quit_item = NSMenuItem(title: "退出", action: #selector(a_exitApp(sender:)), keyEquivalent: "Q")
        menu.addItem(quit_item)
        
    }
    
    /// 关于
    @objc fileprivate func a_aboutApp(sender: NSMenuItem) {
        
        //        NSWorkspace.shared.open(URL(string: "https://github.com/")!)
        if (self.a_aboutVC != nil && self.mainWindow != nil) {
            /// 将当前 app 的 window 放到最前面
            NSApp.activate(ignoringOtherApps: true)
            return}
        let a_about = AboutViewController()
        self.a_aboutVC = a_about
        let a_mainWindow = NSWindow(contentViewController: a_about)
        
        a_mainWindow.delegate = self
        a_mainWindow.titlebarAppearsTransparent = true
        a_mainWindow.titleVisibility = .hidden
        //        a_mainWindow.styleMask = [.fullSizeContentView,
        //                                      .titled,
        //                                      .resizable,
        //                                      .miniaturizable,
        //                                      .closable]
        a_mainWindow.styleMask = [.titled,.closable]
        a_mainWindow.isMovableByWindowBackground = true
        a_mainWindow.backgroundColor = NSColor.white
        
        self.a_updateTitleBarOfWindow(window: a_mainWindow, fullScreen: false)
        
        NSApp.activate(ignoringOtherApps: true)
        a_mainWindow.makeKeyAndOrderFront(self)
        self.mainWindow = a_mainWindow
        
    }
    
    fileprivate func a_dealClose() {
        /// 关闭window的
        self.mainWindow?.performClose(nil)
    }
    
    
    
    /// 退出登录
    @objc fileprivate func a_exitApp(sender: NSMenuItem) {
        
        NSApplication.shared.terminate(self)
    }
    
    
    /// 开机启动
    @objc fileprivate func a_handleStartAtLogin(sender: NSMenuItem) {
        
        if let a_isEnabled = sender.representedObject as? Bool {
            
            CommonTools().z_setStartAtLoginEnabled(enabled: !a_isEnabled)
            
            
            sender.representedObject = !a_isEnabled
            if a_isEnabled == true {
                sender.state = .on
            } else {
                sender.state = .off
            }
            
        }
    }
    
    
    
    
    /// 3.1.1.1 打开指定item
    @objc fileprivate func a_openInWithModifier(sender: NSMenuItem) {
        let event = NSApp.currentEvent
        
        if ((event?.modifierFlags) != nil) && (event?.modifierFlags == NSEvent.ModifierFlags.option) {
            self.a_openInTerminal(sender: sender)
        } else if ((event?.modifierFlags) != nil) && (event?.modifierFlags == NSEvent.ModifierFlags.control) {
            
        } else {
            self.a_openInFinder(sender: sender)
        }
        
        
    }
    
    /// 用终端代开
    @objc fileprivate func a_openInTerminal(sender: NSMenuItem) {
        guard let a_path = sender.representedObject as? String else {
            return
        }
        
        NSWorkspace.shared.openFile(a_path, withApplication: "Terminal")
        
    }
    
    @objc fileprivate func a_openIniTerm(sender: NSMenuItem) {
        guard let a_path = sender.representedObject as? String else {
            return
        }
        
        NSWorkspace.shared.openFile(a_path, withApplication: "iTerm")
        
    }
    
    /// 用Finder打开指定文件夹
    @objc fileprivate func a_openInFinder(sender: NSMenuItem) {
        guard let a_path = sender.representedObject as? String else {
            return
        }
        /// 打开Documents
        let a_docPath = a_path + "Documents"
        NSWorkspace.shared.openFile(a_docPath, withApplication: "Finder")
    }
    
    ///
    @objc fileprivate func a_copyToPasteboard(sender: NSMenuItem) {
        guard let a_path = sender.representedObject as? String else {
            return
        }
        
        let a_pasteboard = NSPasteboard.general
        a_pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        a_pasteboard.setString(a_path, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// 是否有模拟器在运行
    fileprivate func a_simulatorRunning() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(CGWindowListOption.excludeDesktopElements, kCGNullWindowID) as? [[String: AnyObject]] else {
            return false
        }
        
        for a_window in windows {
            guard let windowOwner = a_window[kCGWindowOwnerName as String] as? String,
                let windowName = a_window[kCGWindowName as String] as? String else {
                    return false
            }
            
            let a_ownercontains_Simulator = windowOwner.contains("Simulator")
            let a_name_contains_iOS_watchOS_tvOS = (windowName.contains("iOS") || windowName.contains("watchOS") || windowName.contains("tvOS"))
            
            if a_ownercontains_Simulator && a_name_contains_iOS_watchOS_tvOS {
                return true
            }
            
        }
        
        return false
        
    }
    
    /// 屏幕截图
    @objc fileprivate func a_takeScreenshot(sender: NSMenuItem) {
        
        CommonTools.z_takeScreenshot()
        
    }
    ///
    @objc fileprivate func a_resetApplication(sender: NSMenuItem) {
        guard let a_path = sender.representedObject as? String else {
            return
        }
        self.a_resetFolder(folder: "Documents", root: a_path)
        self.a_resetFolder(folder: "Library", root: a_path)
        self.a_resetFolder(folder: "tmp", root: a_path)
    }
    
    
    fileprivate func a_resetFolder(folder: String, root: String) {
        
        let path = (root as NSString).appendingPathComponent(folder)
        let fm = FileManager.default
        
        let en = fm.enumerator(atPath: path)
        
        while let file = en?.nextObject()  {
            if let a_file = file as? String {
                let a_path = (path as NSString).appendingPathComponent(a_file)
                
                try? fm.removeItem(atPath: a_path)
            }
        }
        
    }
    
    /// 3.1.2 继续添加item
    fileprivate func a_addSubMenusToItem(a_item: NSMenuItem, usingPath: String)  {
        var icon: NSImage?
        
        let subMenu = NSMenu()
        
        var hotkey: Int = 1
        
        let finder_item = NSMenuItem(title: "Finder", action: #selector(a_openInFinder(sender:)), keyEquivalent: "\(hotkey)")
        
        finder_item.representedObject = usingPath
        
        icon = NSWorkspace.shared.icon(forFile: FINDER_ICON_PATH)
        icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
        finder_item.image = icon
        
        subMenu.addItem(finder_item)
        
        hotkey = hotkey + 1
        
        let terminal_item = NSMenuItem(title: "Terminal", action: #selector(a_openInTerminal(sender:)), keyEquivalent: "\(hotkey)")
        terminal_item.representedObject = usingPath
        
        icon = NSWorkspace.shared.icon(forFile: TERMINAL_ICON_PATH)
        icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
        terminal_item.image = icon
        
        subMenu.addItem(terminal_item)
        
        hotkey = hotkey + 1
        
        guard let iTermBundleID = CFStringCreateWithCString(kCFAllocatorDefault, "com.googlecode.iterm2", CFStringBuiltInEncodings.UTF8.rawValue) else {
            return }
        if let _ = LSCopyApplicationURLsForBundleIdentifier(iTermBundleID, nil) {
            
            let iTerm = NSMenuItem(title: "iTerm", action: #selector(a_openIniTerm(sender:)), keyEquivalent: "\(hotkey)")
            iTerm.representedObject = usingPath
            
            icon = NSWorkspace.shared.icon(forFile: ITERM_ICON_PATH)
            
            icon?.size = NSMakeSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
            iTerm.image = icon
            
            subMenu.addItem(iTerm)
            
            hotkey = hotkey + 1
            
        }
        
        subMenu.addItem(NSMenuItem.separator())
        
        let pasteboard_item = NSMenuItem(title: "Copy path to Clipboard", action: #selector(a_copyToPasteboard(sender:)), keyEquivalent: "\(hotkey)")
        
        pasteboard_item.representedObject = usingPath
        subMenu.addItem(pasteboard_item)
        
        hotkey = hotkey + 1
        
        if self.a_simulatorRunning() == true {
            let screenshot_item = NSMenuItem(title: "Copy path to Clipboard", action: #selector(a_takeScreenshot(sender:)), keyEquivalent: "\(hotkey)")
            
            screenshot_item.representedObject = usingPath
            subMenu.addItem(screenshot_item)
            
            hotkey = hotkey + 1
            
        }
        
        let resetApplication_item = NSMenuItem(title: "Reset application data", action: #selector(a_resetApplication(sender:)), keyEquivalent: "\(hotkey)")
        
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
    fileprivate func a_closeWindowAction() {
        if self.mainWindow != nil && self.a_aboutVC != nil {
            self.a_aboutVC = nil
            self.mainWindow = nil
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        /// false时 不能关闭
        return true
    }
    func windowWillClose(_ notification: Notification) {
        self.a_closeWindowAction()
        
        //        debugPrint("------->")
    }
    
    ///
    fileprivate func a_updateTitleBarOfWindow(window: NSWindow ,fullScreen: Bool) {
        let kTitlebarHeight: CGFloat = 24.0
//        let kFullScreenButtonYOrigin: CGFloat = 3.0
        let windowFrame = window.frame
        let titlebarContainerView = window.standardWindowButton(.closeButton)?.superview?.superview;
        
        if let titlebarContainerFrame = titlebarContainerView?.frame {
            var a_titlebarContainerFrame = titlebarContainerFrame
            a_titlebarContainerFrame.origin.y = windowFrame.size.height - kTitlebarHeight
            a_titlebarContainerFrame.size.height = CGFloat(kTitlebarHeight)
            a_titlebarContainerFrame.size.width = 80.0
            titlebarContainerView?.frame = a_titlebarContainerFrame
        }
        
        let buttonX:CGFloat = 6.0
        let closeButton = window.standardWindowButton(.closeButton)
        if let temp_rect = closeButton?.frame {
            var a_temp_rect = temp_rect
            if let a_size = (closeButton?.frame.size) {
                a_temp_rect.size = a_size
                a_temp_rect.origin = CGPoint(x: buttonX, y: round((kTitlebarHeight - temp_rect.height)/2.0))
                closeButton?.frame = a_temp_rect
            }
        }
        
        let minimizeButton = window.standardWindowButton(.miniaturizeButton)
        minimizeButton?.frame = CGRect.zero
        let zoomButton = window.standardWindowButton(.zoomButton)
        zoomButton?.frame = CGRect.zero
        
    }
    
}
