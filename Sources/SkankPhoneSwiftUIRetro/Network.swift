import SwiftUI
import UIKit

// --- 1. Network 主選單介面 ---
struct NetworkView: View {
    @Binding var currentApp: AppState
    
    // 控制子介面顯示的狀態
    @State private var showPreferenceInterface = false
    @State private var showPINInterface = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        if showPreferenceInterface {
            PreferenceView(showPreferenceInterface: $showPreferenceInterface)
        } else if showPINInterface {
            PINView(showPINInterface: $showPINInterface)
        } else {
            VStack(spacing: 0) {
                StatusBarView()
                
                Spacer().frame(height: 30)
                
                // 中間五個藍色設定按鈕
                VStack(spacing: 12) {
                    networkMenuButton(title: "GSM Settings", color: skankBlue) {}
                    
                    networkMenuButton(title: "Wifi Settings", color: skankBlue) {
                        // 打開系統 WiFi 設定
                        if let url = URL(string: "App-Prefs:root=WIFI") {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    networkMenuButton(title: "Bluetooth Settings", color: skankBlue) {}
                    
                    networkMenuButton(title: "Development Settings", color: skankBlue) {}
                    
                    networkMenuButton(title: "Preferences", color: skankBlue) {
                        showPreferenceInterface = true // 打開 Preference 介面
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 偏左下的密碼介面按鈕
                HStack {
                    Button(action: { showPINInterface = true }) {
                        Text("Unlock PIN (3)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(skankBlue)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.leading, 30)
                .padding(.bottom, 20)
                
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
    
    // 共用的藍色長條按鈕元件
    private func networkMenuButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
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


// --- 2. Preference 介面 ---
struct PreferenceView: View {
    @Binding var showPreferenceInterface: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer()
            
            // 暗了的無動作按鈕
            Button(action: {}) {
                Text("Line ID Restriction N/A")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(Color(red: 0.7, green: 0.2, blue: 0.2)) // 暗紅色
                    .cornerRadius(8)
            }
            .padding(.horizontal, 25)
            .disabled(true) // 強制設定為無動作
            
            Spacer()
            
            // 底部 Main Menu 按鈕 (藍色)
            Button(action: {
                showPreferenceInterface = false // 退回 Network 主頁
            }) {
                Text("Main Menu")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 160, height: 40)
                    .background(Color(red: 0.2, green: 0.6, blue: 1.0)) // 藍色
                    .cornerRadius(8)
            }
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
    }
}


// --- 3. 密碼 (PIN) 介面 ---
struct PINView: View {
    @Binding var showPINInterface: Bool
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            Spacer().frame(height: 20)
            
            // 頂部狀態文字
            Text("Disconnected")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 15)
            
            // 鍵盤主體 (依照截圖分成 5 欄排列)
            HStack(alignment: .top, spacing: 5) {
                // 第 1 欄 (左邊綠色按鈕)
                VStack(spacing: 5) {
                    Color.clear.frame(height: 62) // 頂部留空兩格對齊
                    Color.clear.frame(height: 62)
                    actionButton(title: "Call\nPrefs", color: .green) {}
                    actionButton(title: "Send pin", color: .green) {} // 無作用按鈕
                }
                
                // 第 2 欄
                VStack(spacing: 5) {
                    numButton(letters: "", num: "1")
                    numButton(letters: "GHI", num: "4")
                    numButton(letters: "PQRS", num: "7")
                    numButton(letters: "", num: "*")
                }
                
                // 第 3 欄
                VStack(spacing: 5) {
                    numButton(letters: "ABC", num: "2")
                    numButton(letters: "JKL", num: "5")
                    numButton(letters: "TUV", num: "8")
                    numButton(letters: "", num: "0")
                }
                
                // 第 4 欄
                VStack(spacing: 5) {
                    numButton(letters: "DEF", num: "3")
                    numButton(letters: "MNO", num: "6")
                    numButton(letters: "WXYZ", num: "9")
                    numButton(letters: "", num: "#")
                }
                
                // 第 5 欄 (右邊藍色與橙色按鈕)
                VStack(spacing: 5) {
                    actionButton(title: "Delete", color: skankBlue) {}
                    actionButton(title: "Clear", color: skankBlue) {}
                    actionButton(title: "+/,", color: skankBlue) {}
                    actionButton(title: "Menu", color: skankRed) {
                        showPINInterface = false // 退回 Network 主頁
                    }
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 6)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // --- 輔助 UI 元件 ---
    
    @ViewBuilder
    private func numButton(letters: String, num: String) -> some View {
        Button(action: {}) { // 暫時留空功能
            VStack(spacing: -1) {
                if !letters.isEmpty {
                    Text(letters).font(.system(size: 11, weight: .regular))
                } else {
                    Text(" ").font(.system(size: 11))
                }
                Text(num).font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(skankBlue)
            .cornerRadius(8)
        }
    }
    
    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(color)
                .cornerRadius(8)
        }
    }
}
