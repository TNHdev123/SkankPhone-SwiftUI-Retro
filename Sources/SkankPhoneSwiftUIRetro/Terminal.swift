import SwiftUI

struct TerminalView: View {
    @Binding var currentApp: AppState
    
    // 模擬截圖中嘅終端機文字
    let terminalText = """
    iperf Done
    kill: usage: kill [-s..or kill -l [sigspec]
    No command in /usr/loc_c/subtests/custom.txt
    No command in /usr/loc_c/subtests/custom.txt
    No command in /usr/loc_c/subtests/custom.txt
    """
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        // 嚴格跟隨新 App 嘅標準排版結構
        VStack(spacing: 0) {
            // 1. 必須呼叫共用嘅狀態列
            StatusBarView()
            
            // 2. 終端機內容區域
            HStack(spacing: 0) {
                // 左側綠色代碼文字
                Text(terminalText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
                    .background(Color.black)
                
                // 右側假滑桿 (完全灰色，不能滑動)
                Rectangle()
                    .fill(Color(red: 0.8, green: 0.8, blue: 0.8))
                    .frame(width: 20)
                    .frame(maxHeight: .infinity)
            }
            
            // 3. 底部按鈕
            HStack(spacing: 6) {
                terminalButton(title: "Clear") {}
                terminalButton(title: "Reload") {}
                terminalButton(title: "Pick") {}
                terminalButton(title: "Main Menu") {
                    currentApp = .main // 返回主頁
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(Color.black)
        }
        // 確保背景全黑並無視安全區
        .background(Color.black.ignoresSafeArea())
    }
    
    // 獨立抽出底部按鈕樣式
    private func terminalButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(skankBlue)
                .cornerRadius(12)
        }
    }
}
