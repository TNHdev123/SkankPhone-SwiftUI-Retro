import SwiftUI

// --- 1. Test Tool 主介面 ---
struct TestView: View {
    @Binding var currentApp: AppState
    
    @State private var showTerminal = false
    @State private var showATCommands = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        ZStack {
            if showTerminal {
                TerminalView(currentApp: $currentApp)
            } else if showATCommands {
                SendATCommandsView(currentApp: $currentApp)
            } else {
                VStack(spacing: 0) {
                    StatusBarView()
                    
                    Spacer().frame(height: 20)
                    
                    VStack(spacing: 12) {
                        testButton(title: "Ping google.com x10") {}
                        testButton(title: "ping google.com x10K") {}
                        testButton(title: "Run iPerf") {}
                        testButton(title: "Custom") {
                            showTerminal = true
                        }
                        testButton(title: "Bluetooth") {}
                        testButton(title: "Automation") {}
                        testButton(title: "Send AT Commands") {
                            showATCommands = true
                        }
                        testButton(title: "MTDPI") {}
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
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
    
    private func testButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
}

// --- 2. Send AT Commands 介面 ---
struct SendATCommandsView: View {
    @Binding var currentApp: AppState // 接收 currentApp 以實現直達主頁
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 橫向嘅「沒用灰色滑桿」
            Rectangle()
                .fill(Color(red: 0.75, green: 0.75, blue: 0.75))
                .frame(height: 22)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 0) {
                // 左側黑底白框區域 (終端機顯示區)
                Rectangle()
                    .fill(Color.black)
                    .border(Color.white, width: 2)
                    .padding(.leading, 8)
                    .padding(.vertical, 8)
                    .padding(.trailing, 4)
                
                // 右側橫向按鈕列
                VStack(spacing: 0) {
                    // Exit 按鈕改為直達主頁
                    sideButton(title: "Exit", color: skankBlue) {
                        currentApp = .main
                    }
                    sideButton(title: "Keyboard", color: skankRed) {}
                    sideButton(title: "Commands", color: skankRed) {}
                    sideButton(title: "Clear", color: skankBlue) {}
                    
                    Spacer()
                }
                .frame(width: 44)
                .padding(.vertical, 8)
                .padding(.trailing, 4)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // 修正旋轉方向 (-90度)
    private func sideButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 95, height: 36)
                .background(color)
                .cornerRadius(6)
        }
        .frame(width: 36, height: 95)
        .rotationEffect(.degrees(-90)) // 修正文字方向
        .padding(.bottom, 2)
    }
}
