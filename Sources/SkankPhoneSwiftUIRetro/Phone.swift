import SwiftUI

struct PhoneView: View {
    @Binding var currentApp: AppState
    @State private var dialString = ""
    
    // SkankOS 經典藍色
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 1. 數字顯示區 (修正：移除所有背景顏色，純黑底)
            Text(dialString.isEmpty ? " " : dialString)
                .font(.system(size: 34))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 60)
            
            // 頂部小按鈕
            HStack {
                topButton(title: "Camera", color: .green) {
                    currentApp = .camera
                }
                Spacer()
                Text("Disconnected")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                topButton(title: "Monitor", color: .green) {}
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            
            // 2. 鍵盤主體佈局 (修正：改為左、中、右三大直排)
            HStack(spacing: 6) {
                
                // --- 左邊功能列 ---
                VStack(spacing: 6) {
                    sideButton(title: "Voice\nmail", color: skankBlue) {}
                    sideButton(title: "Audio\nPrefs", color: .green) {}
                    sideButton(title: "Call\nPrefs", color: .green) {}
                    
                    Spacer() // 將 Send 按鈕推到最底
                    
                    // 致電按鈕 (修正：比較下方、比較大)
                    largeSideButton(title: "Send", color: .green) {
                        triggerCall()
                    }
                }
                .frame(width: 75) // 鎖死左右兩側闊度
                
                // --- 中間數字鍵盤 ---
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        numButton(letters: "", num: "1")
                        numButton(letters: "ABC", num: "2")
                        numButton(letters: "DEF", num: "3")
                    }
                    HStack(spacing: 6) {
                        numButton(letters: "GHI", num: "4")
                        numButton(letters: "JKL", num: "5")
                        numButton(letters: "MNO", num: "6")
                    }
                    HStack(spacing: 6) {
                        numButton(letters: "PQRS", num: "7")
                        numButton(letters: "TUV", num: "8")
                        numButton(letters: "WXYZ", num: "9")
                    }
                    HStack(spacing: 6) {
                        numButton(letters: "", num: "*")
                        numButton(letters: "", num: "0")
                        numButton(letters: "", num: "#")
                    }
                }
                
                // --- 右邊功能列 ---
                VStack(spacing: 6) {
                    sideButton(title: "Delete", color: skankBlue) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                    sideButton(title: "Clear", color: skankBlue) {
                        dialString = ""
                    }
                    sideButton(title: "+/,", color: skankBlue) {
                        dialString.append("+")
                    }
                    
                    Spacer() // 將 Menu 按鈕推到最底
                    
                    // 退出按鈕 (修正：比較下方、比較大、使用紅色)
                    largeSideButton(title: "Menu", color: .red) {
                        currentApp = .main
                    }
                }
                .frame(width: 75) // 鎖死左右兩側闊度
            }
            .frame(maxWidth: 380) // 限制最大闊度
            .padding(.horizontal, 5)
            .padding(.top, 5)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // --- 輔助 UI 元件與邏輯功能 ---
    
    private func triggerCall() {
        guard !dialString.isEmpty else { return }
        let encoded = dialString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dialString
        if let url = URL(string: "tel://\(encoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // 數字鍵 (高度 65)
    @ViewBuilder
    private func numButton(letters: String, num: String) -> some View {
        Button(action: { dialString.append(num) }) {
            VStack(spacing: -2) {
                if !letters.isEmpty {
                    Text(letters).font(.system(size: 11, weight: .regular))
                } else {
                    Text(" ").font(.system(size: 11))
                }
                Text(num).font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 65, maxHeight: 65)
            .background(skankBlue)
            .cornerRadius(6)
        }
    }
    
    // 兩側一般功能鍵 (高度 65)
    private func sideButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.system(size: 13))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 65, maxHeight: 65)
                .background(color)
                .cornerRadius(6)
        }
    }
    
    // 底部特別大嘅功能鍵 (Send / Menu) (高度 75，字體稍大)
    private func largeSideButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 75, maxHeight: 75) // 比普通按鈕高
                .background(color)
                .cornerRadius(6)
        }
    }
    
    // 頂部 Camera / Monitor 小按鈕
    private func topButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(12)
        }
    }
}
