import SwiftUI

struct PhoneView: View {
    @Binding var currentApp: AppState
    @State private var dialString = ""
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 數字顯示區 (改回置中對齊，背景微灰)
            Text(dialString.isEmpty ? " " : dialString)
                .font(.system(size: 34))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 60)
                .background(Color(white: 0.15))
            
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
            
            // 鍵盤主體佈局
            VStack(spacing: 5) {
                // 第一行
                HStack(spacing: 5) {
                    actionButton(title: "Voice\nmail", color: Color(red: 0.2, green: 0.6, blue: 1.0)) {}
                    numButton(letters: "", num: "1")
                    numButton(letters: "ABC", num: "2")
                    numButton(letters: "DEF", num: "3")
                    actionButton(title: "Delete", color: Color(red: 0.2, green: 0.6, blue: 1.0)) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                }
                
                // 第二行
                HStack(spacing: 5) {
                    actionButton(title: "Audio\nPrefs", color: .green) {}
                    numButton(letters: "GHI", num: "4")
                    numButton(letters: "JKL", num: "5")
                    numButton(letters: "MNO", num: "6")
                    actionButton(title: "Clear", color: Color(red: 0.2, green: 0.6, blue: 1.0)) {
                        dialString = ""
                    }
                }
                
                // 第三行
                HStack(spacing: 5) {
                    actionButton(title: "Call\nPrefs", color: .green) {}
                    numButton(letters: "PQRS", num: "7")
                    numButton(letters: "TUV", num: "8")
                    numButton(letters: "WXYZ", num: "9")
                    actionButton(title: "+/,", color: Color(red: 0.2, green: 0.6, blue: 1.0)) {
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
                    actionButton(title: "Menu", color: .red) {
                        currentApp = .main
                    }
                }
            }
            // 限制最大闊度，防止喺大芒機被過度向橫拉伸
            .frame(maxWidth: 380)
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
    
    // 數字鍵 (修正：英文字母在上，數字在下)
    @ViewBuilder
    private func numButton(letters: String, num: String) -> some View {
        Button(action: { dialString.append(num) }) {
            VStack(spacing: -2) {
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
            .frame(maxWidth: .infinity, minHeight: 65, maxHeight: 65) // 鎖死高度為 65
            .background(Color(red: 0.2, green: 0.6, blue: 1.0))
            .cornerRadius(6) // 圓角收細
        }
    }
    
    // 兩側功能鍵
    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
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
    
    // 頂部 Camera / Monitor 小按鈕
    private func topButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(12) // 保持膠囊形狀
        }
    }
}
