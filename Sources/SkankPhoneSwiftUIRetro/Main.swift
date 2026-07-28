import SwiftUI
import Combine
import UIKit

@main
struct SkankPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 1. 隱藏頂部系統狀態列
                .statusBarHidden(true)
                // 2. 條件式隱藏 Home Bar (避免 iOS 15 編譯報錯)
                .hideHomeBarIfPossible()
        }
    }
}

// 相容 iOS 16+ 嘅 Home Bar 隱藏修飾符
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

struct ContentView: View {
    // 用於儲存當前時間嘅狀態
    @State private var currentTime = ""
    
    // 設定一個每秒觸發一次嘅計時器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 按鈕嘅標籤陣列
    let buttonLabels = [
        "Phone", "SMS",
        "Web", "Media",
        "Network\nSettings", "Power\nSettings",
        "More Other", "Playground",
        "Test Tools", "Operator"
    ]
    
    // 定義網格嘅佈局：兩欄，彈性寬度
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ZStack {
            // 黑色背景，延伸至安全區域之外（填滿全螢幕）
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 頂部灰色狀態列
                HStack {
                    Spacer() // 將時間推去右邊
                    Text(currentTime)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .regular))
                }
                .padding(.horizontal, 10)
                .frame(height: 35)
                .background(Color(white: 0.6)) // 狀態列灰色背景
                
                Spacer().frame(height: 15)
                
                // 2. 號碼狀態文字
                Text("Num: [No Data]")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                
                Spacer().frame(height: 25)
                
                // 3. 藍色按鈕網格
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(buttonLabels, id: \.self) { label in
                        Button(action: {
                            // 暫時無作用
                            print("\(label) tapped")
                        }) {
                            Text(label)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.4)) // 按鈕內嘅深藍色字
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color(red: 0.2, green: 0.6, blue: 1.0)) // SkankOS 風格嘅亮藍色
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 30) // 網格左右邊距
                
                Spacer() // 佔用剩餘空間，將底部文字推向下
                
                // 4. 底部機密/版本文字
                VStack(spacing: 5) {
                    Text("S/N: 5K809BGGWH8")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Text("[Skank is the new black] [04.04.05_G]")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .padding(.bottom, 20)
            }
        }
        // 當接收到計時器更新時，刷新時間
        .onReceive(timer) { input in
            updateTime(date: input)
        }
        // 介面出現時獨立初始化時間
        .onAppear {
            updateTime(date: Date())
        }
    }
    
    // 獨立出一個更新時間嘅 function 方便管理
    private func updateTime(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 24小時制
        currentTime = formatter.string(from: date)
    }
}
