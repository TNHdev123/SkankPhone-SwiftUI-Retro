import SwiftUI
import Combine
import UIKit

// 全域狀態
enum AppState {
    case main, phone, camera, sms, web, media, network, power, more, terminal, playground, test, hb3d, purple
}

// --- App 設定資料模型 (精準對應 image_17.png 嘅純字串結構) ---
struct AppConfig: Codable, Identifiable {
    var id: String { appID }
    
    let appID: String
    let appName: String
    let color: String
    let nameColor: String
    let appView: String
    
    // 強制對應 plist 嘅大階 Key
    enum CodingKeys: String, CodingKey {
        case appID = "AppID"
        case appName = "AppName"
        case color = "Color"
        case nameColor = "NameColor"
        case appView = "AppView"
    }
    
    // 將 "r,g,b,a" 格式嘅字串，解析並強制轉換成 Display P3 顏色
    private func parseDisplayP3(from colorString: String) -> Color {
        let components = colorString.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if components.count >= 3 {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            let a = components.count >= 4 ? components[3] : 1.0
            return Color(.displayP3, red: r, green: g, blue: b, opacity: a)
        }
        return Color.black // 預設防錯顏色
    }
    
    // 提供畀 UI 直接呼叫嘅 Display P3 Color
    var buttonColorP3: Color { parseDisplayP3(from: color) }
    var nameColorP3: Color { parseDisplayP3(from: nameColor) }
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
                case .hb3d:
                    HomeButton3DView(currentApp: $currentApp)
                case .purple:
                    PurpleView(currentApp: $currentApp)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// 主選單視圖
struct MainMenuView: View {
    @Binding var currentApp: AppState
    
    @State private var installedApps: [AppConfig] = []
    @State private var wallpaper: UIImage? = nil
    
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ZStack {
            // 背景層
            if let bg = wallpaper {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // UI 互動層
            VStack(spacing: 0) {
                StatusBarView()
                Spacer().frame(height: 15)
                Text("Num: [No Data]").foregroundColor(.white).font(.system(size: 18))
                Spacer().frame(height: 25)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(installedApps) { app in
                        Button(action: {
                            handleAppLaunch(targetView: app.appView)
                        }) {
                            Text(app.appName)
                                .multilineTextAlignment(.center)
                                // 呼叫轉譯後嘅 Display P3 顏色
                                .foregroundColor(app.nameColorP3)
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(app.buttonColorP3)
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
        case "hb3d": currentApp = .hb3d
        case "purple": currentApp = .purple
        default: print("未知目標視圖: \(targetView)")
        }
    }
    
    // --- 讀取或建立 Applications.plist ---
    private func loadOrSetupAppList() -> [AppConfig] {
        // 設定 Display P3 字串格式 "R,G,B,A"
        let skankBlueStr = "0.2,0.6,1.0,1.0"
        let blackColorStr = "0.0,0.0,0.0,1.0"
        
        let defaultApps = [
            AppConfig(appID: "com.skank.phone", appName: "Phone", color: skankBlueStr, nameColor: blackColorStr, appView: "phone"),
            AppConfig(appID: "com.skank.sms", appName: "SMS", color: skankBlueStr, nameColor: blackColorStr, appView: "sms"),
            AppConfig(appID: "com.skank.web", appName: "Web", color: skankBlueStr, nameColor: blackColorStr, appView: "web"),
            AppConfig(appID: "com.skank.media", appName: "Media", color: skankBlueStr, nameColor: blackColorStr, appView: "media"),
            AppConfig(appID: "com.skank.network", appName: "Network\nSettings", color: skankBlueStr, nameColor: blackColorStr, appView: "network"),
            AppConfig(appID: "com.skank.power", appName: "Power\nSettings", color: skankBlueStr, nameColor: blackColorStr, appView: "power"),
            AppConfig(appID: "com.skank.more", appName: "More Other", color: skankBlueStr, nameColor: blackColorStr, appView: "more"),
            AppConfig(appID: "com.skank.playground", appName: "Playground", color: skankBlueStr, nameColor: blackColorStr, appView: "playground"),
            AppConfig(appID: "com.skank.test", appName: "Test Tools", color: skankBlueStr, nameColor: blackColorStr, appView: "test"),
            AppConfig(appID: "com.skank.operator", appName: "Operator", color: skankBlueStr, nameColor: blackColorStr, appView: "none")
        ]
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return defaultApps }
        let systemDir = documentDirectory.appendingPathComponent("System/SkankPhone")
        let plistURL = systemDir.appendingPathComponent("Applications.plist")
        
        if FileManager.default.fileExists(atPath: plistURL.path) {
            if let data = try? Data(contentsOf: plistURL),
               let savedApps = try? PropertyListDecoder().decode([AppConfig].self, from: data) {
                return savedApps // 讀取成功
            } else {
                // 格式錯誤 (例如讀取到 image_16 嗰種舊格式)，強行覆蓋重建
                saveAppsToPlist(apps: defaultApps, url: plistURL)
                return defaultApps
            }
        } else {
            // 檔案不存在，建立資料夾並儲存
            do {
                try FileManager.default.createDirectory(at: systemDir, withIntermediateDirectories: true, attributes: nil)
                saveAppsToPlist(apps: defaultApps, url: plistURL)
            } catch {
                print("建立資料夾失敗: \(error)")
            }
            return defaultApps
        }
    }
    
    // 獨立儲存邏輯，輸出乾淨嘅 XML 格式
    private func saveAppsToPlist(apps: [AppConfig], url: URL) {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(apps)
            try data.write(to: url)
        } catch {
            print("寫入 Applications.plist 失敗: \(error)")
        }
    }
    
    // --- 讀取最新 Wallpaper ---
    private func getLatestWallpaper() -> UIImage? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let wallpaperURL = documentDirectory.appendingPathComponent("System/Wallpaper")
        
        if !FileManager.default.fileExists(atPath: wallpaperURL.path) {
            do {
                try FileManager.default.createDirectory(at: wallpaperURL, withIntermediateDirectories: true, attributes: nil)
            } catch { return nil }
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
        } catch { return nil }
        
        return nil
    }
}
