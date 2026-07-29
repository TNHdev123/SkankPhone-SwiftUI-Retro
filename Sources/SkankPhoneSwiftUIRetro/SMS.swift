import SwiftUI

// --- 1. SMS 主選單介面 (還原 image_13.png) ---
struct SMSView: View {
    @Binding var currentApp: AppState
    @State private var showSendInterface = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        // 如果觸發了發送介面，就顯示 SMSSendView
        if showSendInterface {
            SMSSendView(currentApp: $currentApp, showSendInterface: $showSendInterface)
        } else {
            VStack(spacing: 0) {
                StatusBarView()
                
                Spacer().frame(height: 20)
                
                // 藍色按鈕清單
                VStack(spacing: 12) {
                    // 上面五個藍色按鈕：觸發同一個功能（打開發送介面）
                    ForEach(1...5, id: \.self) { i in
                        smsMenuButton(title: "SMS Test Message \(i)", color: skankBlue) {
                            showSendInterface = true
                        }
                    }
                    
                    // 之後兩個藍色按鈕：觸發同一個功能（打開 sms://）
                    smsMenuButton(title: "Compose a message", color: skankBlue) {
                        openSMSApp()
                    }
                    smsMenuButton(title: "View Messages", color: skankBlue) {
                        openSMSApp()
                    }
                }
                .padding(.horizontal, 25)
                
                Spacer() // 將紅色按鈕推到最底
                
                // 底部 Main Menu 按鈕（比較小且置底）
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Main Menu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 160, height: 40) // 寬度比藍色按鈕小
                        .background(skankRed)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
    
    // 打開系統 SMS 程式
    private func openSMSApp() {
        if let url = URL(string: "sms://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // 藍色按鈕的共用元件
    private func smsMenuButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
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


// --- 2. SMS 發送介面 (你提供的程式碼，稍微改名避免衝突) ---
struct SMSSendView: View {
    @Binding var currentApp: AppState
    @Binding var showSendInterface: Bool // 用來控制返回上一頁
    @State private var dialString = ""
    
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
                topButton(title: "      ", color: .black) {}
                Spacer()
                Text("Disconnected")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                topButton(title: "Monitor", color: .green) {}
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // 3. 鍵盤主體
            HStack(alignment: .top, spacing: 5) {
                VStack(spacing: 5) {
                    actionButton(title: "", color: .black) {}
                    actionButton(title: "", color: .black) {}
                    actionButton(title: "Call\nPrefs", color: .green) {}
                }
                .padding(.top, 33.5)
                
                VStack(spacing: 5) {
                    numButton(letters: "", num: "1")
                    numButton(letters: "GHI", num: "4")
                    numButton(letters: "PQRS", num: "7")
                    numButton(letters: "", num: "*")
                }
                
                VStack(spacing: 5) {
                    numButton(letters: "ABC", num: "2")
                    numButton(letters: "JKL", num: "5")
                    numButton(letters: "TUV", num: "8")
                    numButton(letters: "", num: "0")
                }
                
                VStack(spacing: 5) {
                    numButton(letters: "DEF", num: "3")
                    numButton(letters: "MNO", num: "6")
                    numButton(letters: "WXYZ", num: "9")
                    numButton(letters: "", num: "#")
                }
                
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
            
            Spacer()
            
            // 4. 底部 Send / Menu 按鈕
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
                
                // 按下 Menu 鍵，回到主畫面 (currentApp = .main)
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
        if let url = URL(string: "sms://\(encoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
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
