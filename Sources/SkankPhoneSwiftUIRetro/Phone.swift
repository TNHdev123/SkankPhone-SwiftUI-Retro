import SwiftUI

struct PhoneView: View {
    @Binding var currentApp: AppState
    @State private var dialString = ""
    
    // SkankOS 經典藍色與紅色
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 1. 號碼顯示區 (修正：完全無背景顏色，純黑底)
            Text(dialString.isEmpty ? " " : dialString)
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 55)
                .padding(.top, 10)
            
            // 2. 頂部 Camera / Disconnected / Monitor 列
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // 3. 鍵盤主體 (嚴格 4 行 x 5 列，每行水平對齊)
            VStack(spacing: 5) {
                // 第一行
                HStack(spacing: 5) {
                    actionButton(title: "Voice\nmail", color: skankBlue) {}
                    numButton(letters: "", num: "1")
                    numButton(letters: "ABC", num: "2")
                    numButton(letters: "DEF", num: "3")
                    actionButton(title: "Delete", color: skankBlue) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                }
                
                // 第二行
                HStack(spacing: 5) {
                    actionButton(title: "Audio\nPrefs", color: .green) {}
                    numButton(letters: "GHI", num: "4")
                    numButton(letters: "JKL", num: "5")
                    numButton(letters: "MNO", num: "6")
                    actionButton(title: "Clear", color: skankBlue) {
                        dialString = ""
                    }
                }
                
                // 第三行
                HStack(spacing: 5) {
                    actionButton(title: "Call\nPrefs", color: .green) {}
                    numButton(letters: "PQRS", num: "7")
                    numButton(letters: "TUV", num: "8")
                    numButton(letters: "WXYZ", num: "9")
                    actionButton(title: "+/,", color: skankBlue) {
                        dialString.append("+")
                    }
                }
                
                // 第四行
                HStack(spacing: 5) {
                    actionButton(title: "Send", color: .green) {
                        triggerCall()
                    }
                    numButton(letters: "", num: "*")
                    numButton(letters: "", num: "0")
                    numButton(letters: "", num: "#")
                    actionButton(title: "Menu", color: skankRed) {
                        currentApp = .main
                    }
                }
            }
            .frame(maxWidth: 420) // 限制最大闊度，避免喺大芒機拉得太散
            .padding(.horizontal, 6)
            .padding(.top, 4)
            
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
    
    // 數字鍵 (英文字母在上、數字在下)
    @ViewBuilder
    private func numButton(letters: String, num: String) -> some View {
        Button(action: { dialString.append(num) }) {
            VStack(spacing: -1) {
                if !letters.isEmpty {
                    Text(letters)
                        .font(.system(size: 11, weight: .regular))
                } else {
                    Text(" ")
                        .font(.system(size: 11))
                }
                Text(num)
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(skankBlue)
            .cornerRadius(8)
        }
    }
    
    // 兩側功能鍵
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
    
    // 頂部 Camera / Monitor 小按鈕
    private func topButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(10)
        }
    }
}
