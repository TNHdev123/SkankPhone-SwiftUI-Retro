import SwiftUI
import Combine
import UIKit

// 全域狀態：用嚟控制目前顯示咩畫面
enum AppState {
    case main, phone, camera, sms, web, media, network, power, more, terminal, playground, test
}

// --- 專為 plist 儲存 Display P3 顏色設計嘅結構 ---
struct DisplayP3Color: Codable {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
    
    // 將儲存嘅數值強制轉換為 SwiftUI 嘅 Display P3 Color
    var swiftUIColor: Color {
        return Color(.displayP3, red: r, green: g, blue: b, opacity: a)
    }
}

// --- App 設定資料模型 (對應 Applications.plist) ---
struct AppConfig: Codable, Identifiable {
    var id: String { appID } // 滿足 Identifiable，方便 ForEach 使用
    
    let appID: String
    let buttonName: String
    let buttonColor: DisplayP3Color // 明確使用自訂嘅 Display P3 結構
    let nameColor: DisplayP3Color
    let targetView: String          // 對應 AppState 嘅字串，例如 "phone"，冇就填 "none"
}

@main
struct SkankPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
                .hideHomeBarIfPossible()
        }
    }
}

// 根據 iOS 16 判斷隱藏 Home Bar
extension View {
    @ViewBuilder
    func hideHomeBarIfPossible() -> some View {
        if #available(iOS 16.0, *) {
            self.persistentSystemOverlays(.hidden)
        } else {
            self
        }
    }
}

// 共用元件：頂部灰色狀態列
struct StatusBarView: View {
    @State private var currentTime = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Spacer()
            Text(currentTime)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .regular))
        }
        .padding(.horizontal, 10)
        .frame(height: 35)
        .background(Color(white: 0.6))
        .onReceive(timer) { input in updateTime(date: input) }
        .onAppear { updateTime(date: Date()) }
    }
    
    private func updateTime(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: date)
    }
}

// 根視圖：負責切換畫面
struct RootView: View {
    @State private var currentApp: AppState = .main
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Group {
                switch currentApp {
                case .main:
                    MainMenuView(currentApp: $currentApp)
                case .phone:
                    PhoneView(currentApp: $currentApp)
                case .camera:
                    CameraView(currentApp: $currentApp)
                case .sms:
                    SMSView(currentApp: $currentApp)
                case .web:
                    WebView(currentApp: $currentApp)
                case .media:
                    MediaView(currentApp: $currentApp)
                case .network:
                    NetworkView(currentApp: $currentApp)
                case .power:
                    PowerView(currentApp: $currentApp)
                case .more:
                    MoreView(currentApp: $currentApp)
                case .terminal:
                    TerminalView(currentApp: $currentApp)
                case .playground:
                    PlaygroundView(currentApp: $currentApp)
                case .test:
                    TestView(currentApp: $currentApp)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// 主選單視圖
struct MainMenuView: View {
    @Binding var currentApp: AppState
    
    // 動態載入的 App 設定與桌布
    @State private var installedApps: [AppConfig] = []
    @State private var wallpaper: UIImage? = nil
    
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ZStack {
            // --- 背景層 ---
            if let bg = wallpaper {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // --- UI 互動層 ---
            VStack(spacing: 0) {
                StatusBarView()
                Spacer().frame(height: 15)
                Text("Num: [No Data]").foregroundColor(.white).font(.system(size: 18))
                Spacer().frame(height: 25)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(installedApps) { app in
                        Button(action: {
                            handleAppLaunch(targetView: app.targetView)
                        }) {
                            Text(app.buttonName)
                                .multilineTextAlignment(.center)
                                // 直接調用結構入面嘅 swiftUIColor (已鎖定 Display P3)
                                .foregroundColor(app.nameColor.swiftUIColor)
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(app.buttonColor.swiftUIColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                VStack(spacing: 5) {
                    Text("S/N: 5K809BGGWH8").foregroundColor(.white).font(.system(size: 14))
                    Text("[Skank is the new black] [04.04.05_G]").foregroundColor(.white).font(.system(size: 12))
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            installedApps = loadOrSetupAppList()
            wallpaper = getLatestWallpaper()
        }
    }
    
    // 處理 App 啟動路由
    private func handleAppLaunch(targetView: String) {
        switch targetView.lowercased() {
        case "phone": currentApp = .phone
        case "camera": currentApp = .camera
        case "sms": currentApp = .sms
        case "web": currentApp = .web
        case "media": currentApp = .media
        case "network": currentApp = .network
        case "power": currentApp = .power
        case "more": currentApp = .more
        case "terminal": currentApp = .terminal
        case "playground": currentApp = .playground
        case "test": currentApp = .test
        case "none": break
        default: print("未知目標視圖: \(targetView)")
        }
    }
    
    // --- 讀取或建立 Applications.plist ---
    private func loadOrSetupAppList() -> [AppConfig] {
        // 使用明確嘅 DisplayP3Color 初始化
        let skankBlue = DisplayP3Color(r: 0.2, g: 0.6, b: 1.0, a: 1.0)
        let blackColor = DisplayP3Color(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
        
        // 預設的 App 列表
        let defaultApps = [
            AppConfig(appID: "com.skank.phone", buttonName: "Phone", buttonColor: skankBlue, nameColor: blackColor, targetView: "phone"),
            AppConfig(appID: "com.skank.sms", buttonName: "SMS", buttonColor: skankBlue, nameColor: blackColor, targetView: "sms"),
            AppConfig(appID: "com.skank.web", buttonName: "Web", buttonColor: skankBlue, nameColor: blackColor, targetView: "web"),
            AppConfig(appID: "com.skank.media", buttonName: "Media", buttonColor: skankBlue, nameColor: blackColor, targetView: "media"),
            AppConfig(appID: "com.skank.network", buttonName: "Network\nSettings", buttonColor: skankBlue, nameColor: blackColor, targetView: "network"),
            AppConfig(appID: "com.skank.power", buttonName: "Power\nSettings", buttonColor: skankBlue, nameColor: blackColor, targetView: "power"),
            AppConfig(appID: "com.skank.more", buttonName: "More Other", buttonColor: skankBlue, nameColor: blackColor, targetView: "more"),
            AppConfig(appID: "com.skank.playground", buttonName: "Playground", buttonColor: skankBlue, nameColor: blackColor, targetView: "playground"),
            AppConfig(appID: "com.skank.test", buttonName: "Test Tools", buttonColor: skankBlue, nameColor: blackColor, targetView: "test"),
            AppConfig(appID: "com.skank.operator", buttonName: "Operator", buttonColor: skankBlue, nameColor: blackColor, targetView: "none")
        ]
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return defaultApps }
        let systemDir = documentDirectory.appendingPathComponent("System/SkankPhone")
        let plistURL = systemDir.appendingPathComponent("Applications.plist")
        
        if FileManager.default.fileExists(atPath: plistURL.path) {
            // 讀取現有 plist
            if let data = try? Data(contentsOf: plistURL),
               let savedApps = try? PropertyListDecoder().decode([AppConfig].self, from: data) {
                return savedApps
            }
        } else {
            // 自動製作資料夾同 plist
            do {
                try FileManager.default.createDirectory(at: systemDir, withIntermediateDirectories: true, attributes: nil)
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .xml // 輸出 XML 格式方便後續直接用文字編輯器修改
                let data = try encoder.encode(defaultApps)
                try data.write(to: plistURL)
            } catch {
                print("建立 Applications.plist 失敗: \(error)")
            }
        }
        return defaultApps
    }
    
    // --- 讀取最新 Wallpaper ---
    private func getLatestWallpaper() -> UIImage? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let wallpaperURL = documentDirectory.appendingPathComponent("System/Wallpaper")
        
        if !FileManager.default.fileExists(atPath: wallpaperURL.path) {
            do {
                try FileManager.default.createDirectory(at: wallpaperURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("建立 Wallpaper 資料夾失敗: \(error)")
            }
            return nil
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: wallpaperURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            let sortedFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "heic"
            }.sorted { u1, u2 in
                let date1 = (try? u1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? u2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            if let latestURL = sortedFiles.first {
                return UIImage(contentsOfFile: latestURL.path)
            }
        } catch {
            print("讀取 Wallpaper 失敗: \(error)")
        }
        
        return nil
    }
}
