import SwiftUI
import Combine
import UIKit

// --- (保留你原本嘅 AppState, SkankPhoneApp, hideHomeBarIfPossible 同 StatusBarView) ---

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
                    // 假設你有 PhoneView，如果未有可以先註解
                    Text("Phone View").foregroundColor(.white) // 替換為你的 PhoneView(currentApp: $currentApp)
                case .camera:
                    Text("Camera View").foregroundColor(.white) // 替換為你的 CameraView
                case .sms:
                    Text("SMS View").foregroundColor(.white) // 替換為你的 SMSView
                case .web:
                    Text("Web View").foregroundColor(.white) // 替換為你的 WebView
                case .media:
                    MediaView(currentApp: $currentApp)
                }
            }
            .ignoresSafeArea(edges: .top) // <- 全域生效，所有子畫面頂部都會貼緊螢幕最上方[span_2](start_span)[span_2](end_span)
        }
    }
}


// --- 新增：主選單資料控制器 ---
class MainMenuManager: ObservableObject {
    @Published var buttonLabels: [String] = []
    @Published var wallpaperImage: UIImage? = nil
    
    func loadData() {
        loadPlist()
        loadWallpaper()
    }
    
    // 讀取或建立 Applications.plist
    private func loadPlist() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let systemDir = docsURL.appendingPathComponent("System/SkankPhone")
        let plistURL = systemDir.appendingPathComponent("Applications.plist")
        
        if FileManager.default.fileExists(atPath: plistURL.path) {
            // 如果檔案存在，讀取 Plist
            if let data = try? Data(contentsOf: plistURL),
               let array = try? PropertyListDecoder().decode([String].self, from: data) {
                self.buttonLabels = array
            }
        } else {
            // 如果檔案唔存在，使用預設值並建立 Plist
            let defaultLabels = [
                "Phone", "SMS", "Web", "Media",
                "Network\nSettings", "Power\nSettings",
                "More Other", "Playground",
                "Test Tools", "Operator"
            ] //[span_3](start_span)[span_3](end_span)
            self.buttonLabels = defaultLabels
            
            do {
                try FileManager.default.createDirectory(at: systemDir, withIntermediateDirectories: true)
                let data = try PropertyListEncoder().encode(defaultLabels)
                try data.write(to: plistURL)
                print("成功建立預設 Applications.plist")
            } catch {
                print("建立 Plist 失敗: \(error)")
            }
        }
    }
    
    // 讀取最新嘅 Wallpaper
    private func loadWallpaper() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let wallpaperDir = docsURL.appendingPathComponent("System/Wallpaper")
        
        do {
            // 確保資料夾存在
            if !FileManager.default.fileExists(atPath: wallpaperDir.path) {
                try FileManager.default.createDirectory(at: wallpaperDir, withIntermediateDirectories: true)
            }
            
            // 讀取並搵出最新圖片[span_4](start_span)[span_4](end_span)
            let files = try FileManager.default.contentsOfDirectory(at: wallpaperDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)[span_5](start_span)[span_5](end_span)
            
            let sortedFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "heic"
            }.sorted { u1, u2 in
                let date1 = (try? u1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? u2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }[span_6](start_span)[span_6](end_span)
            
            if let latestURL = sortedFiles.first {
                self.wallpaperImage = UIImage(contentsOfFile: latestURL.path)
            } else {
                self.wallpaperImage = nil
            }
        } catch {
            print("讀取 Wallpaper 失敗: \(error)")
        }
    }
}


// --- 修改後嘅主選單視圖 ---
struct MainMenuView: View {
    @Binding var currentApp: AppState
    @StateObject private var manager = MainMenuManager()
    
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)][span_7](start_span)[span_7](end_span)

    var body: some View {
        ZStack {
            // 1. 底層：Wallpaper 或 全黑背景
            if let wallpaper = manager.wallpaperImage {
                Image(uiImage: wallpaper)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // 確保 Wallpaper 不能夠互動，點擊會穿透
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // 2. 表層：UI 介面
            VStack(spacing: 0) {
                StatusBarView()
                Spacer().frame(height: 15)
                Text("Num: [No Data]")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1) // 加少少陰影確保背景花嘅時候都睇到字
                
                Spacer().frame(height: 25)
                
                LazyVGrid(columns: columns, spacing: 20) {[span_8](start_span)[span_8](end_span)
                    ForEach(manager.buttonLabels, id: \.self) { label in
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
                        }[span_9](start_span)[span_9](end_span)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                VStack(spacing: 5) {
                    Text("S/N: 5K809BGGWH8").foregroundColor(.white).font(.system(size: 14))[span_10](start_span)[span_10](end_span)
                    Text("[Skank is the new black] [04.04.05_G]").foregroundColor(.white).font(.system(size: 12))[span_11](start_span)[span_11](end_span)
                }
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            manager.loadData() // 每次出現時重新讀取 Plist 同 Wallpaper
        }
    }
}
