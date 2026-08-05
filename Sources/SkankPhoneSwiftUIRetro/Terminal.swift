import SwiftUI

struct TerminalView: View {
    @Binding var currentApp: AppState
    
    // 根據截圖定義嘅顏色
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let statusBarBg = Color(red: 0.55, green: 0.65, blue: 0.75) // 頂部狀態列專屬灰藍色
    
    // 模擬截圖中嘅綠色終端機文字
    let mockOutput = """
    iperf Done
    kill: usage: kill [-s..or kill -l [sigspec]]
    No command in /usr/loc...c/subtests/custom.t
    No command in /usr/loc...c/subtests/custom.t
    No command in /usr/loc...c/subtests/custom.t
    """
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- 頂部自訂狀態列 ---
            HStack {
                // 左側綠色假訊號線
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 15))
                    path.addLine(to: CGPoint(x: 5, y: 5))
                    path.addLine(to: CGPoint(x: 10, y: 10))
                    path.addLine(to: CGPoint(x: 15, y: 0))
                }
                .stroke(Color.green, lineWidth: 2)
                .frame(width: 20, height: 15)
                .padding(.leading, 10)
                
                Spacer()
                
                // 右側時間
                Text("6:23")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
            .frame(height: 35)
            .background(statusBarBg)
            .padding(.top, 40) // 預留頂部安全區
            .background(statusBarBg.ignoresSafeArea(edges: .top))
            
            
            // --- 中間終端機畫面 + 假捲動軸 ---
            HStack(spacing: 0) {
                // 左邊黑底綠字區域
                VStack(alignment: .leading) {
                    Text(mockOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.green)
                        .lineSpacing(2)
                        .padding(4)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black)
                
                // 右邊完全灰色且不能滑動的假捲動軸
                Rectangle()
                    .fill(Color(white: 0.75))
                    .frame(width: 25)
            }
            
            // --- 底部按鈕列 ---
            HStack(spacing: 8) {
                terminalButton(title: "Clear")
                terminalButton(title: "Reload")
                terminalButton(title: "Pick")
                
                // Main Menu 按鈕，用作退出返回主頁
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Main Menu")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(skankBlue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 50)
            .background(Color.black)
            .padding(.bottom, 20) // 預留底部安全區
            .background(Color.black.ignoresSafeArea(edges: .bottom))
            
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // 生成無作用按鈕嘅 Helper
    private func terminalButton(title: String) -> some View {
        Button(action: {
            // 冇任何作用
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(skankBlue)
                .clipShape(Capsule())
        }
    }
}
