import SwiftUI
import UIKit

// --- 1. MoreOther 主選單介面 ---
struct MoreOtherView: View {
    @Binding var currentApp: AppState
    
    @State private var showBrightness = false
    @State private var showFT = false
    @State private var showFactory = false
    @State private var isShutdown = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        ZStack {
            if showBrightness {
                BrightnessView(currentApp: $currentApp, showBrightness: $showBrightness)
            } else if showFT {
                FTView(currentApp: $currentApp, showFT: $showFT)
            } else if showFactory {
                FactoryTestView(currentApp: $currentApp, showFactory: $showFactory)
            } else {
                // 主介面
                VStack(spacing: 0) {
                    StatusBarView()
                    
                    Spacer().frame(height: 30)
                    
                    VStack(spacing: 12) {
                        moreButton(title: "Brightness") { showBrightness = true }
                        moreButton(title: "Field Test") { showFT = true }
                        moreButton(title: "Factory Test") { showFactory = true }
                        
                        Spacer().frame(height: 15)
                        
                        moreButton(title: "Terminal") {}
                        
                        // Quit (退回主畫面，完美避開 unused result 警告)
                        moreButton(title: "Quit") {
                            let suspendSelector = NSSelectorFromString("suspend")
                            if UIApplication.shared.responds(to: suspendSelector) {
                                _ = UIApplication.shared.perform(suspendSelector)
                            }
                        }
                        
                        // Shutdown
                        moreButton(title: "Shutdown") {
                            isShutdown = true
                        }
                    }
                    .padding(.horizontal, 30)
                    
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
                .background(Color.black.ignoresSafeArea())
            }
            
            // --- Shutdown 關機全黑圖層 ---
            if isShutdown {
                Color.black
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isShutdown = false
                        currentApp = .main // 按住1秒回到主頁
                    }
            }
        }
    }
    
    private func moreButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
}


// --- 2. 亮度 (Brightness) 介面 ---
struct BrightnessView: View {
    @Binding var currentApp: AppState
    @Binding var showBrightness: Bool
    
    @State private var brightnessValue: CGFloat = UIScreen.main.brightness
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer().frame(height: 20)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Brightness:")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    // 自訂滑桿
                    CustomBrightnessSlider(value: $brightnessValue)
                    
                    // 顯示 0 - 100 數值
                    Text("\(Int(brightnessValue * 100))")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 35, alignment: .trailing)
                }
            }
            .padding(.horizontal, 25)
            
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
        .background(Color.black.ignoresSafeArea())
    }
}

// --- 2.1 自訂亮度滑桿元件 (完全移除了 ViewBuilder 內的變數宣告，保證能編譯) ---
struct CustomBrightnessSlider: View {
    @Binding var value: CGFloat // 0.0 至 1.0
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 灰色底線
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 2)
                
                // 藍色直條拉桿 (利用 geometry.size 直接運算，避免宣告 let)
                Rectangle()
                    .fill(skankBlue)
                    .frame(width: 4, height: 26)
                    .offset(x: max(0, min((geometry.size.width * value) - 2, geometry.size.width - 4)))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = min(max(CGFloat(0), gesture.location.x / geometry.size.width), CGFloat(1.0))
                        value = newValue
                        UIScreen.main.brightness = newValue
                    }
            )
        }
        .frame(height: 30)
    }
}


// --- 3. FT (Field Test) 介面 ---
struct FTView: View {
    @Binding var currentApp: AppState
    @Binding var showFT: Bool
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer().frame(height: 30)
            
            VStack(spacing: 12) {
                ftButton(title: "Network Info")
                ftButton(title: "Cell Info")
                ftButton(title: "SCell Info")
            }
            .padding(.horizontal, 30)
            
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
        .background(Color.black.ignoresSafeArea())
    }
    
    private func ftButton(title: String) -> some View {
        Button(action: {
            openFTMApp()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
    
    // 透過 Bundle ID 打開 FTMInternal-4.app (最嚴格安全嘅 Private API 寫法)
    private func openFTMApp() {
        let possibleBundleIDs = ["com.apple.FTMInternal", "com.apple.fieldtest"]
        
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type {
            let defaultWorkspaceSelector = NSSelectorFromString("defaultWorkspace")
            
            if workspaceClass.responds(to: defaultWorkspaceSelector),
               let workspace = workspaceClass.perform(defaultWorkspaceSelector)?.takeUnretainedValue() as? NSObject {
                
                let openSelector = NSSelectorFromString("openApplicationWithBundleID:")
                if workspace.responds(to: openSelector) {
                    for bundleID in possibleBundleIDs {
                        _ = workspace.perform(openSelector, with: bundleID)
                    }
                    return // 成功觸發就退出
                }
            }
        }
        
        // 備用方案
        if let url = URL(string: "fieldtest://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}


// --- 4. 工廠 (Factory Test) 介面 ---
struct FactoryTestView: View {
    @Binding var currentApp: AppState
    @Binding var showFactory: Bool
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let skankDarkBlue = Color(red: 0.1, green: 0.25, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 將按鈕推落去靠底
            Spacer()
            
            VStack(spacing: 12) {
                factoryButton(title: "Start Burn-In", color: skankBlue) {}
                
                // Restart Cycling (暗色，無法點擊)
                Button(action: {}) {
                    Text("Restart Cycling")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(skankDarkBlue)
                        .cornerRadius(8)
                }
                .disabled(true)
                
                factoryButton(title: "Battery Discharge", color: skankBlue) {}
                factoryButton(title: "Reset Tests", color: skankBlue) {}
                
                // Exit 按鈕 (紅色，回到主頁)
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
        .background(Color.black.ignoresSafeArea())
    }
    
    private func factoryButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
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
