import SwiftUI
import Combine
import UIKit

// 全域狀態：用嚟控制目前顯示咩畫面
enum AppState {
    case main, phone, camera, sms, web, media, network, power, more, terminal, playground
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

// 根視圖：負責切換畫面（在此處進行全域安全區控制）
struct RootView: View {
    @State private var currentApp: AppState = .main
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 用 Group 包住切換邏輯，全域移除頂部安全區
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
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// 主選單視圖
struct MainMenuView: View {
    @Binding var currentApp: AppState
    
    // 動態載入的 App 列表與桌布
    @State private var buttonLabels: [String] = []
    @State private var wallpaper: UIImage? = nil
    
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ZStack {
            // --- 背景層：Wallpaper 或 全黑 ---
            if let bg = wallpaper {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // 確保 Wallpaper 不能夠直接互動
            } else {
                Color.black.ignoresSafeArea() // 找不到 Wallpaper 就依然以全黑作底
            }
            
            // --- UI 互動層 ---
            VStack(spacing: 0) {
                StatusBarView()
                Spacer().frame(height: 15)
                Text("Num: [No Data]").foregroundColor(.white).font(.system(size: 18))
                Spacer().frame(height: 25)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(buttonLabels, id: \.self) { label in
                        Button(action: {
                            switch label { 
                            case "Phone":
                                currentApp = .phone
                            case "SMS":
                                currentApp = .sms
                            case "Web":
                                currentApp = .web
                            case "Media":
                                currentApp = .media
                            case "Network\nSettings":
                                currentApp = .network
                            case "Power\nSettings":
                                currentApp = .power
                            case "More Other":
                                currentApp = .more
                            case "Playground":
                                currentApp = .playground
                            default:
                                print("\(label) tapped")
                            }
                        }) {
                            Text(label)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color(red: 0.2, green: 0.6, blue: 1.0))
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
            // 每次回到主畫面時，重新載入設定同桌布
            buttonLabels = loadOrSetupAppList()
            wallpaper = getLatestWallpaper()
        }
    }
    
    // --- 讀取或建立 Applications.plist (轉用 PropertyListEncoder 更安全) ---
    private func loadOrSetupAppList() -> [String] {
        let defaultApps = [
            "Phone", "SMS", "Web", "Media",
            "Network\nSettings", "Power\nSettings",
            "More Other", "Playground",
            "Test Tools", "Operator"
        ]
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return defaultApps }
        let systemDir = documentDirectory.appendingPathComponent("System/SkankPhone")
        let plistURL = systemDir.appendingPathComponent("Applications.plist")
        
        if FileManager.default.fileExists(atPath: plistURL.path) {
            // 如果檔案存在，讀取 plist 內容
            if let data = try? Data(contentsOf: plistURL),
               let savedApps = try? PropertyListDecoder().decode([String].self, from: data) {
                return savedApps
            }
        } else {
            // 如果冇，就自動製作資料夾同 plist
            do {
                try FileManager.default.createDirectory(at: systemDir, withIntermediateDirectories: true, attributes: nil)
                let data = try PropertyListEncoder().encode(defaultApps)
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
        
        // 檢查並建立資料夾
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
            
            // 取得最新一張
            if let latestURL = sortedFiles.first {
                return UIImage(contentsOfFile: latestURL.path)
            }
        } catch {
            print("讀取 Wallpaper 失敗: \(error)")
        }
        
        return nil
    }
}
