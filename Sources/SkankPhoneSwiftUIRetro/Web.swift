import SwiftUI
import Combine
import UIKit
import WebKit

// --- Web App 主視圖 ---
struct WebView: View {
    @Binding var currentApp: AppState
    
    // 建立一個固定的 WKWebView 實體，方便我哋呼叫 goBack() 同 reload()
    let webView = WKWebView()
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 網頁顯示區域
            SkankWebView(webView: webView, url: URL(string: "https://www.youtube.com")!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white) // 避免載入前出現黑屏
            
            // 底部 4 個藍色功能按鈕
            HStack(spacing: 4) {
                bottomButton(title: "Back") {
                    webView.goBack() // 返回上一頁
                }
                bottomButton(title: "Reload") {
                    webView.reload() // 重新載入
                }
                bottomButton(title: "Bookmarks") {
                    print("Bookmarks tapped") // 暫時閒置
                }
                bottomButton(title: "Menu") {
                    currentApp = .main // 回到主頁
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 15) // 稍微推高一點，避免貼死底邊
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // 底部按鈕共用元件
    @ViewBuilder
    private func bottomButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
}

// --- 將 UIKit 的 WKWebView 封裝給 SwiftUI 使用 ---
struct SkankWebView: UIViewRepresentable {
    let webView: WKWebView
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        // 設定允許向後/向前滑動導覽 (類似 Safari 側滑返回)
        webView.allowsBackForwardNavigationGestures = true
        
        // 載入初始網址
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 網頁由 WKWebView 內部狀態管理，此處無需額外更新
    }
}
