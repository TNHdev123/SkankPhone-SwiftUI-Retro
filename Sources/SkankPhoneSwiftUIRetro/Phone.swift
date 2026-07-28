import SwiftUI

struct PhoneView: View {
    @Binding var currentApp: AppState
    @State private var dialString = ""
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 1. 數字顯示區 (修正：加入行數限制與自動縮小)
            Text(dialString.isEmpty ? " " : dialString)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .lineLimit(1) // 限制只有一行
                .minimumScaleFactor(0.4) // 字串太長時自動縮小字體
                .truncationMode(.head) // 真係無位時，省略最前面嘅數字
                .frame(maxWidth: .infinity, alignment: .trailing) // 號碼靠右顯示更自然
                .frame(height: 50) // 鎖死高度，避免撐開排版
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color(white: 0.0)) // 黑色底
            
            // 頂部小按鈕
            HStack {
                topButton(title: "Camera", color: .green) {
                    currentApp = .camera
                }
                Spacer()
                Text("Disconnected")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                topButton(title: "Monitor", color: .green) {}
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            
            // 2. 鍵盤主體佈局 (修正：改用逐行 HStack 確保完美對齊)
            VStack(spacing: 5) {
                // 第一行
                HStack(spacing: 5) {
                    actionButton(title: "Voice\nmail", color: Color(red: 0.2, green: 0.6, blue: 1.0), width: 70) {}
                    numButton(num: "1", letters: "")
                    numButton(num: "2", letters: "ABC")
                    numButton(num: "3", letters: "DEF")
                    actionButton(title: "Delete", color: Color(red: 0.2, green: 0.6, blue: 1.0), width: 70) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                }
                
                // 第二行
                HStack(spacing: 5) {
                    actionButton(title: "Audio\nPrefs", color: .green, width: 70) {}
                    numButton(num: "4", letters: "GHI")
                    numButton(num: "5", letters: "JKL")
                    numButton(num: "6", letters: "MNO")
                    actionButton(title: "Clear", color: Color(red: 0.2, green: 0.6, blue: 1.0), width: 70) {
                        dialString = ""
                    }
                }
                
                // 第三行
                HStack(spacing: 5) {
                    actionButton(title: "Call\nPrefs", color: .green, width: 70) {}
                    numButton(num: "7", letters: "PQRS")
                    numButton(num: "8", letters: "TUV")
                    numButton(num: "9", letters: "WXYZ")
                    actionButton(title: "+/-", color: Color(red: 0.2, green: 0.6, blue: 1.0), width: 70) {
                        dialString.append("+")
                    }
                }
                
                // 第四行
                HStack(spacing: 5) {
                    actionButton(title: "Send", color: .green, width: 70) {
                        triggerCall() // 修正：觸發系統致電
                    }
                    numButton(num: "*", letters: "")
                    numButton(num: "0", letters: "")
                    numButton(num: "#", letters: "")
                    actionButton(title: "Menu", color: .red, width: 70) {
                        currentApp = .main
                    }
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // --- 輔助 UI 元件與邏輯功能 ---
    
    // 觸發系統致電功能
    private func triggerCall() {
        guard !dialString.isEmpty else { return }
        // 必須將 # 等特殊符號編碼為 %23，否則 iOS 無法識別 tel URL
        let encoded = dialString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dialString
        if let url = URL(string: "tel://\(encoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // 數字鍵專用按鈕 (包含英文字母)
    @ViewBuilder
    private func numButton(num: String, letters: String) -> some View {
        Button(action: { dialString.append(num) }) {
            VStack(spacing: -2) { // 微微拉近數字同字母嘅距離
                Text(num)
                    .font(.system(size: 26, weight: .bold))
                if !letters.isEmpty {
                    Text(letters)
                        .font(.system(size: 10, weight: .bold))
                } else {
                    // 放一個空白字元撐住高度，保證沒有字母的按鍵一樣高
                    Text(" ")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.black) // 修正：強制文字為黑色
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60) // 鎖死高度為 60
            .background(Color(red: 0.2, green: 0.6, blue: 1.0))
            .cornerRadius(8)
        }
    }
    
    // 兩側功能鍵
    private func actionButton(title: String, color: Color, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(.black) // 修正：強制文字為黑色
                .frame(width: width, height: 60) // 鎖死闊度同高度
                .background(color)
                .cornerRadius(8)
        }
    }
    
    // 頂部 Camera / Monitor 小按鈕
    private func topButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.black) // 修正：強制文字為黑色
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(8)
        }
    }
}
