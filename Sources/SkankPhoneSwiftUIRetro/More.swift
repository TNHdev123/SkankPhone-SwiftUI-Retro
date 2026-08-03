import SwiftUI
import UIKit

// 控制 More 介面入面唔同嘅子頁面
enum MorePage {
    case main
    case brightness
    case fieldTest
    case factoryTest
}

// --- More 總入口介面 ---
struct MoreView: View {
    @Binding var currentApp: AppState
    @State private var currentPage: MorePage = .main
    @State private var isShutdown = false // 控制 Shutdown 的全黑畫面
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0) // 橙紅色
    let disabledBlue = Color(red: 0.15, green: 0.25, blue: 0.6) // 暗藍色
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 根據 currentPage 顯示對應的介面
            switch currentPage {
            case .main:
                moreMainInterface
            case .brightness:
                BrightnessView(currentPage: $currentPage, currentApp: $currentApp)
            case .fieldTest:
                FieldTestView(currentPage: $currentPage, currentApp: $currentApp)
            case .factoryTest:
                FactoryTestView(currentPage: $currentPage, currentApp: $currentApp)
            }
            
            // Shutdown 全黑遮罩 (覆蓋在最上層)
            if isShutdown {
                Color.black
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isShutdown = false // 長按 1 秒解鎖並返回介面
                    }
            }
        }
    }
    
    // --- 1. MoreOther 主介面 (參考 image_6.png) ---
    private var moreMainInterface: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer().frame(height: 20)
            
            // 上半部按鈕群組
            VStack(spacing: 12) {
                moreButton(title: "Brightness", color: skankBlue) { currentPage = .brightness }
                moreButton(title: "Field Test", color: skankBlue) { currentPage = .fieldTest }
                moreButton(title: "Factory Test", color: skankBlue) { currentPage = .factoryTest }
            }
            .padding(.horizontal, 40)
            
            Spacer().frame(height: 35)
            
            // 下半部按鈕群組
            VStack(spacing: 12) {
                moreButton(title: "Terminal", color: skankBlue) {} // 無特別說明，留空
                moreButton(title: "Quit", color: skankBlue) {
                    exit(0) // 安全退出應用程式
                }
                moreButton(title: "Shutdown", color: skankBlue) {
                    isShutdown = true // 觸發全黑畫面
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
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
    }
    
    // 共用的藍色按鈕元件
    private func moreButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(color)
                .cornerRadius(8)
        }
    }
}

// --- 2. Brightness 亮度介面 (參考 image_7.png) ---
struct BrightnessView: View {
    @Binding var currentPage: MorePage
    @Binding var currentApp: AppState
    
    // 綁定系統亮度 (0.0 到 1.0)
    @State private var brightnessLevel: Double = Double(UIScreen.main.brightness)
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBarView()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Brightness:")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .regular))
                
                HStack {
                    // 自訂 Slider，當數值改變時同步修改系統亮度
                    Slider(value: Binding(
                        get: { self.brightnessLevel },
                        set: { newValue in
                            self.brightnessLevel = newValue
                            UIScreen.main.brightness = CGFloat(newValue) // 即時更新系統亮度
                        }
                    ), in: 0...1)
                    .accentColor(Color(red: 0.2, green: 0.6, blue: 1.0)) // 藍色滑桿線
                    
                    // 顯示 0-100 的亮度數值
                    Text("\(Int(brightnessLevel * 100))")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .regular))
                        .frame(width: 35, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // 置中的 Main Menu 按鈕
            HStack {
                Spacer()
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
                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

// --- 3. Field Test (FT) 介面 (參考 image_8.png) ---
struct FieldTestView: View {
    @Binding var currentPage: MorePage
    @Binding var currentApp: AppState
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer().frame(height: 20)
            
            VStack(spacing: 12) {
                ftButton(title: "Network Info")
                ftButton(title: "Cell Info")
                ftButton(title: "SCell Info")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
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
    }
    
    private func ftButton(title: String) -> some View {
        Button(action: { openFieldTestApp() }) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
    
    // 透過隱藏撥號指令觸發 FTMInternal-4.app
    private func openFieldTestApp() {
        if let url = URL(string: "tel://*3001#12345#*") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// --- 4. Factory Test 介面 (參考 image_9.png) ---
struct FactoryTestView: View {
    @Binding var currentPage: MorePage
    @Binding var currentApp: AppState
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let disabledBlue = Color(red: 0.15, green: 0.25, blue: 0.6) // 暗藍色
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 將所有按鈕推向底部
            Spacer()
            
            VStack(spacing: 12) {
                factoryButton(title: "Start Burn-In", color: skankBlue, isDisabled: false) {}
                
                // Restart Cycling 唯獨是暗色並且無法點擊
                factoryButton(title: "Restart Cycling", color: disabledBlue, isDisabled: true) {}
                
                factoryButton(title: "Battery Discharge", color: skankBlue, isDisabled: false) {}
                factoryButton(title: "Reset Tests", color: skankBlue, isDisabled: false) {}
                
                // Exit 按鈕等同於 Main Menu (置底並轉為紅色)
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Exit")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(skankRed)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    private func factoryButton(title: String, color: Color, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(color)
                .cornerRadius(8)
        }
        .disabled(isDisabled) // 套用無法點擊狀態
    }
}
