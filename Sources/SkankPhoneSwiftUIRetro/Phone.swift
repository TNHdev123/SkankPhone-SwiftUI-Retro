import SwiftUI

struct PhoneView: View {
    @Binding var currentApp: AppState
    @State private var dialString = ""
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 數字顯示區
            Text(dialString.isEmpty ? " " : dialString)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .background(Color(white: 0.2)) // 模擬顯示螢幕底色
            
            // 頂部小按鈕
            HStack {
                actionButton(title: "Camera", color: .green) {
                    currentApp = .camera
                }
                Spacer()
                Text("Disconnected")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                actionButton(title: "Monitor", color: .green) {}
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            
            // 鍵盤主體佈局
            HStack(spacing: 5) {
                // 左側功能鍵
                VStack(spacing: 5) {
                    actionButton(title: "Voice\nmail", color: Color(red: 0.2, green: 0.6, blue: 1.0), height: 60) {}
                    actionButton(title: "Audio\nPrefs", color: .green, height: 60) {}
                    actionButton(title: "Call\nPrefs", color: .green, height: 60) {}
                    Spacer()
                    actionButton(title: "Send", color: .green, height: 50) {
                        print("觸發致電選單")
                    }
                }
                .frame(width: 70)
                
                // 中間數字鍵盤
                let padColumns = [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)]
                LazyVGrid(columns: padColumns, spacing: 5) {
                    ForEach(["1","2","3","4","5","6","7","8","9","*","0","#"], id: \.self) { key in
                        Button(action: {
                            dialString.append(key)
                        }) {
                            Text(key)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color(red: 0.2, green: 0.6, blue: 1.0))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // 右側功能鍵
                VStack(spacing: 5) {
                    actionButton(title: "Delete", color: Color(red: 0.2, green: 0.6, blue: 1.0), height: 60) {
                        if !dialString.isEmpty { dialString.removeLast() }
                    }
                    actionButton(title: "Clear", color: Color(red: 0.2, green: 0.6, blue: 1.0), height: 60) {
                        dialString = ""
                    }
                    actionButton(title: "+/,", color: Color(red: 0.2, green: 0.6, blue: 1.0), height: 60) {
                        dialString.append("+")
                    }
                    Spacer()
                    actionButton(title: "Menu", color: .orange, height: 50) {
                        currentApp = .main
                    }
                }
                .frame(width: 70)
            }
            .padding(.horizontal, 5)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // 自訂義按鈕樣式助手
    private func actionButton(title: String, color: Color, height: CGFloat = 30, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(color == .orange || color == .green ? .black : .init(red: 0.1, green: 0.1, blue: 0.4))
                .frame(maxWidth: .infinity, minHeight: height)
                .background(color)
                .cornerRadius(8)
        }
    }
}
