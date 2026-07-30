import SwiftUI
import UIKit

// --- 1. Media 主選單介面 ---
struct MediaView: View {
    @Binding var currentApp: AppState
    @State private var showPicturesInterface = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        if showPicturesInterface {
            PicturesView(currentApp: $currentApp)
        } else {
            VStack(spacing: 0) {
                StatusBarView()
                
                Spacer().frame(height: 20)
                
                // 藍色按鈕清單
                VStack(spacing: 12) {
                    mediaMenuButton(title: "Music", color: skankBlue) {
                        UIApplication.shared.open(URL(string: "music://")!)
                    }
                    mediaMenuButton(title: "Pictures", color: skankBlue) {
                        showPicturesInterface = true // 打開相片瀏覽介面
                    }
                    mediaMenuButton(title: "Video", color: skankBlue) {
                        UIApplication.shared.open(URL(string: "videos://")!)
                    }
                }
                .padding(.horizontal, 25)
                
                Spacer() // 將紅色按鈕推到最底
                
                // 底部 Main Menu 按鈕
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Main Menu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 160, height: 40)
                        .background(skankRed)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
    
    // 藍色按鈕的共用元件 (修正了原本的方法名稱)
    private func mediaMenuButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 45) // 扁平的長條按鈕
                .background(color)
                .cornerRadius(8)
        }
    }
}

// --- 2. 圖片全螢幕瀏覽介面 ---
struct PicturesView: View {
    @Binding var currentApp: AppState
    
    @State private var images: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var isBlackScreen: Bool = false
    
    var body: some View {
        ZStack {
            // 背景底色
            Color.black.ignoresSafeArea()
            
            // 如果唔係黑屏模式，就顯示相片
            if !isBlackScreen {
                if images.isEmpty {
                    Text("No Pictures Found")
                        .foregroundColor(.gray)
                } else {
                    if let image = UIImage(contentsOfFile: images[currentIndex].path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    } else {
                        Text("Error loading image")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .contentShape(Rectangle()) // 確保點擊或滑動黑屏邊緣都會有反應
        // --- 手勢控制 ---
        .onTapGesture {
            // 單擊：切換黑屏狀態
            isBlackScreen.toggle()
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            // 長按 1 秒：退回主頁
            currentApp = .main
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    // 使用 Transaction 停用切換相片時的動畫
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    
                    withTransaction(transaction) {
                        if value.translation.width > 0 {
                            // 由左至右滑動 -> 切換至更之前的相片 (Index + 1)
                            if currentIndex < images.count - 1 {
                                currentIndex += 1
                            }
                        } else if value.translation.width < 0 {
                            // 由右至左滑動 -> 切換至更新的相片 (Index - 1)
                            if currentIndex > 0 {
                                currentIndex -= 1
                            }
                        }
                    }
                }
        )
        .onAppear {
            loadImages()
        }
        // 完全隱藏系統狀態列
        .statusBarHidden(true)
    }
    
    // --- 讀取圖片檔案並排序 ---
    private func loadImages() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let picturesURL = documentDirectory.appendingPathComponent("Media/Pictures")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: picturesURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            // 過濾出圖片檔案，並根據建立時間排序 (最新嘅喺最前面)
            let sortedFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "heic"
            }.sorted { u1, u2 in
                let date1 = (try? u1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? u2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2 // 時間大嘅排前
            }
            
            self.images = sortedFiles
            self.currentIndex = 0 // 預設顯示最新嘅第一張
        } catch {
            print("讀取圖片失敗: \(error)")
        }
    }
}
