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
            
            // 1. 號碼顯示區
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
            
            // 3. 鍵盤主體 (修正：改為 5 列直排佈局)
            HStack(alignment: .top, spacing: 5) {
                
                // 第一列 (最左邊 3 個按鈕，下移 0.5 格)
                VStack(spacing: 5) {
                    actionButton(title: "Voice\nmail", color: skankBlue) {}
                    actionButton(title: "Audio\nPrefs", color: .green) {}
                    actionButton(title: "Call\nPrefs", color: .green) {}
                }
                .padding(.top, 33.5) // (高度62 + 間距5) / 2 = 33.5
                
                // 第二列 (數字鍵盤左邊)
                VStack(spacing: 5) {
                    numButton(letters: "", num: "1")
                    numButton(letters: "GHI", num: "4")
                    numButton(letters: "PQRS", num: "7")
                    numButton(letters: "", num: "*")
                }
                
                // 第三列 (數字鍵盤中間)
                VStack(spacing: 5) {
                    numButton(letters: "ABC", num: "2")
                    numButton(letters: "JKL", num: "5")
                    numButton(letters: "TUV", num: "8")
                    numButton(letters: "", num: "0")
                }
                
                // 第四列 (數字鍵盤右邊)
                VStack(spacing: 5) {
                    numButton(letters: "DEF", num: "3")
                    numButton(letters: "MNO", num: "6")
                    numButton(letters: "WXYZ", num: "9")
                    numButton(letters: "", num: "#")
                }
                
                // 第五列 (最右邊 3 個按鈕，下移 0.5 格)
                VStack(spacing: 5) {
                    actionButton(title: "Delete", color: skankBlue) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                    actionButton(title: "Clear", color: skankBlue) {
                        dialString = ""
                    }
                    actionButton(title: "+/,", color: skankBlue) {
                        dialString.append("+")
                    }
                }
                .padding(.top, 33.5)
                
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 6)
            .padding(.top, 4)
            
            Spacer() // 將 Send 同 Menu 推落最底
            
            // 4. 底部 Send / Menu 按鈕 (放大並置底)
            HStack {
                Button(action: { triggerCall() }) {
                    Text("Send")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 110, height: 75)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: { currentApp = .main }) {
                    Text("Menu")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 110, height: 75)
                        .background(skankRed)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 25)
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
    
    // 數字鍵 (高度 62)
    @ViewBuilder
    private func numButton(letters: String, num: String) -> some View {
        Button(action: { dialString.append(num) }) {
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
    
    // 兩側一般功能鍵 (高度 62)
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
