import SwiftUI
import Combine
import UIKit

// 全域狀態：用嚟控制目前顯示咩畫面
enum AppState {
    case main, phone, camera, sms, web, media
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
            Color.black.ignoresSafeArea()[span_3](start_span)[span_3](end_span)
            
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
    
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)][span_4](start_span)[span_4](end_span)

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
                StatusBarView()[span_5](start_span)[span_5](end_span)
                Spacer().frame(height: 15)[span_6](start_span)[span_6](end_span)
                Text("Num: [No Data]").foregroundColor(.white).font(.system(size: 18))[span_7](start_span)[span_7](end_span)
                Spacer().frame(height: 25)[span_8](start_span)[span_8](end_span)
                
                LazyVGrid(columns: columns, spacing: 20) {[span_9](start_span)[span_9](end_span)
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
                .padding(.horizontal, 30)[span_10](start_span)[span_10](end_span)
                
                Spacer()
                
                VStack(spacing: 5) {
                    Text("S/N: 5K809BGGWH8").foregroundColor(.white).font(.system(size: 14))[span_11](start_span)[span_11](end_span)
                    Text("[Skank is the new black] [04.04.05_G]").foregroundColor(.white).font(.system(size: 12))[span_12](start_span)[span_12](end_span)
                }
                .padding(.bottom, 20)[span_13](start_span)[span_13](end_span)
            }
        }
        .onAppear {
            // 每次回到主畫面時，重新載入設定同桌布
            buttonLabels = loadOrSetupAppList()
            wallpaper = getLatestWallpaper()
        }
    }
    
    // --- 讀取或建立 Applications.plist ---
    private func loadOrSetupAppList() -> [String] {
        // 原本的預設排列方式
        let defaultApps = [
            "Phone", "SMS", "Web", "Media",
            "Network\nSettings", "Power\nSettings",
            "More Other", "Playground",
            "Test Tools", "Operator"
        ][span_14](start_span)[span_14](end_span)
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return defaultApps }
        let systemDir = documentDirectory.appendingPathComponent("System/SkankPhone")
        let plistURL = systemDir.appendingPathComponent("Applications.plist")
        
        if FileManager.default.fileExists(atPath: plistURL.path) {
            // 如果檔案存在，讀取 plist 內容
            if let savedApps = NSArray(contentsOf: plistURL) as? [String] {
                return savedApps
            }
        } else {
            // 如果冇，就自動製作資料夾同 plist
            do {
                try FileManager.default.createDirectory(at: systemDir, withIntermediateDirectories: true, attributes: nil)
                (defaultApps as NSArray).write(to: plistURL, atomically: true)
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
            // 參考 Media.plist 的讀取與時間排序邏輯
            let files = try FileManager.default.contentsOfDirectory(at: wallpaperURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)[span_15](start_span)[span_15](end_span)
            
            let sortedFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()[span_16](start_span)[span_16](end_span)
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "heic[span_17](start_span)"[span_17](end_span)
            }.sorted { u1, u2 in
                let date1 = (try? u1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast[span_18](start_span)[span_18](end_span)
                let date2 = (try? u2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast[span_19](start_span)[span_19](end_span)
                return date1 > date2[span_20](start_span)[span_20](end_span)
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
