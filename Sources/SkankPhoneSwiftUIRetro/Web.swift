import SwiftUI
import Combine
import UIKit
import WebKit

// --- 1. 新增：用嚟儲存同計算網頁滑動狀態嘅 Object ---
class WebViewState: ObservableObject {
    @Published var contentHeight: CGFloat = 1
    @Published var viewHeight: CGFloat = 1
    @Published var scrollY: CGFloat = 0
    
    // 計算滾動條（紅面）嘅長度比例
    var visibleProportion: CGFloat {
        guard contentHeight > 0 else { return 1 }
        return min(1, viewHeight / contentHeight)
    }
    
    // 計算滾動條（紅面）目前嘅垂直位置比例
    var scrollProportion: CGFloat {
        guard contentHeight > viewHeight else { return 0 }
        let maxScroll = contentHeight - viewHeight
        return max(0, min(1, scrollY / maxScroll))
    }
}

// --- Web App 主視圖 ---
struct WebView: View {
    @Binding var currentApp: AppState
    
    let webView = WKWebView()
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0) // 紅面顏色
    
    // 加入 StateObject 來接收網頁滑動資訊
    @StateObject private var webViewState = WebViewState()
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 網頁顯示區域與自訂滾動條 (利用 HStack 左右排列，確保絕對唔會重疊)
            HStack(spacing: 0) {
                // 左側：網頁主體
                SkankWebView(webView: webView, url: URL(string: "https://www.google.com")!, webViewState: webViewState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                
                // 右側：紅面灰底滾動條
                GeometryReader { geo in
                    let trackHeight = geo.size.height
                    
                    // 設定紅色捲軸最小高度為 20，避免網頁太長時捲軸縮到睇唔到
                    let thumbHeight = max(20, trackHeight * webViewState.visibleProportion)
                    
                    // 計算紅色捲軸嘅 Y 軸位移
                    let maxOffset = trackHeight - thumbHeight
                    let currentOffset = maxOffset * webViewState.scrollProportion
                    
                    ZStack(alignment: .top) {
                        Color(white: 0.75) // 灰底
                        
                        skankRed // 紅面
                            .frame(height: thumbHeight)
                            // 如果 currentOffset 計出嚟係 NaN 就當 0 處理
                            .offset(y: currentOffset.isNaN ? 0 : currentOffset)
                    }
                }
                .frame(width: 25) // 設定滾動條闊度 (可根據需要自行微調)
            }
            
            // 底部 4 個藍色功能按鈕
            HStack(spacing: 4) {
                bottomButton(title: "Back") {
                    webView.goBack()
                }
                bottomButton(title: "Reload") {
                    webView.reload()
                }
                bottomButton(title: "Bookmarks") {
                    print("Bookmarks tapped")
                }
                bottomButton(title: "Menu") {
                    currentApp = .main
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 15)
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
    @ObservedObject var webViewState: WebViewState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.allowsBackForwardNavigationGestures = true
        
        // 隱藏系統預設嘅灰色滾動條，避免同自訂滾動條一齊出現
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // 設定 KVO 監聽滑動狀態
        context.coordinator.setupKVO(for: webView.scrollView)
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 網頁由內部狀態管理，此處無需額外更新
    }
    
    // Coordinator 負責監聽 UIScrollView 嘅變化
    class Coordinator: NSObject {
        var parent: SkankWebView
        var offsetObserver: NSKeyValueObservation?
        var sizeObserver: NSKeyValueObservation?
        
        init(_ parent: SkankWebView) {
            self.parent = parent
        }
        
        func setupKVO(for scrollView: UIScrollView) {
            // 監聽目前滑動位置 (Y軸)
            offsetObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.webViewState.scrollY = view.contentOffset.y
                }
            }
            
            // 監聽網頁內容總高度及目前視窗高度變化
            sizeObserver = scrollView.observe(\.contentSize, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.webViewState.contentHeight = view.contentSize.height
                    self?.parent.webViewState.viewHeight = view.bounds.height
                }
            }
        }
        
        deinit {
            // 釋放記憶體前清除監聽器
            offsetObserver?.invalidate()
            sizeObserver?.invalidate()
        }
    }
}
