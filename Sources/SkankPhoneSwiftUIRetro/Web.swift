import SwiftUI
import Combine
import UIKit
import WebKit

// --- 1. 書籤資料模型與管理器 ---
struct Bookmark: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var url: String
}

class BookmarkManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    
    init() {
        loadBookmarks()
    }
    
    // 取得 /Web/Bookmarks.plist 的路徑
    private func getBookmarksURL() -> URL {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let webDir = docURL.appendingPathComponent("Web")
        
        // 如果 Web 資料夾不存在就建立
        if !FileManager.default.fileExists(atPath: webDir.path) {
            try? FileManager.default.createDirectory(at: webDir, withIntermediateDirectories: true, attributes: nil)
        }
        return webDir.appendingPathComponent("Bookmarks.plist")
    }
    
    func loadBookmarks() {
        guard let data = try? Data(contentsOf: getBookmarksURL()),
              let decoded = try? PropertyListDecoder().decode([Bookmark].self, from: data) else {
            return
        }
        self.bookmarks = decoded
    }
    
    func saveBookmarks() {
        guard let data = try? PropertyListEncoder().encode(bookmarks) else { return }
        try? data.write(to: getBookmarksURL())
    }
    
    func addBookmark(name: String, url: String) {
        bookmarks.append(Bookmark(name: name, url: url))
        saveBookmarks()
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
}

// --- 2. 網頁滑動狀態 Object ---
class WebViewState: ObservableObject {
    @Published var contentHeight: CGFloat = 1
    @Published var viewHeight: CGFloat = 1
    @Published var scrollY: CGFloat = 0
    
    // 這個 Closure 用來讓 SwiftUI 觸發 WKWebView 的滑動
    var setScrollOffset: ((CGFloat) -> Void)?
    
    var visibleProportion: CGFloat {
        guard contentHeight > 0 else { return 1 }
        return min(1, viewHeight / contentHeight)
    }
    
    var scrollProportion: CGFloat {
        guard contentHeight > viewHeight else { return 0 }
        let maxScroll = contentHeight - viewHeight
        return max(0, min(1, scrollY / maxScroll))
    }
}

// --- 3. Web App 主視圖 ---
struct WebView: View {
    @Binding var currentApp: AppState
    
    let webView = WKWebView()
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    @StateObject private var webViewState = WebViewState()
    @StateObject private var bookmarkManager = BookmarkManager()
    @State private var showBookmarks = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StatusBarView()
                
                // 網頁顯示區域與自訂滾動條
                HStack(spacing: 0) {
                    SkankWebView(webView: webView, url: URL(string: "https://www.google.com")!, webViewState: webViewState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    
                    // --- 右側：可觸控拉動的紅面灰底滾動條 ---
                    GeometryReader { geo in
                        let trackHeight = geo.size.height
                        let thumbHeight = max(20, trackHeight * webViewState.visibleProportion)
                        let maxOffset = trackHeight - thumbHeight
                        let currentOffset = maxOffset * webViewState.scrollProportion
                        
                        ZStack(alignment: .top) {
                            Color(white: 0.75) // 灰底
                            
                            skankRed // 紅面
                                .frame(height: thumbHeight)
                                .offset(y: currentOffset.isNaN ? 0 : currentOffset)
                        }
                        .contentShape(Rectangle()) // 讓整個軌道都能感應觸控
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard maxOffset > 0 else { return }
                                    // 將觸控點置中於紅色滾動條
                                    let dragY = value.location.y - (thumbHeight / 2)
                                    let percentage = min(max(dragY / maxOffset, 0), 1)
                                    let maxScrollY = webViewState.contentHeight - webViewState.viewHeight
                                    
                                    // 觸發 WKWebView 滑動
                                    webViewState.setScrollOffset?(percentage * maxScrollY)
                                }
                        )
                    }
                    .frame(width: 25)
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
                        showBookmarks = true
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
            
            // --- 書籤列表彈出視窗 (Popup) ---
            if showBookmarks {
                Color.black.opacity(0.4).ignoresSafeArea() // 背景調暗
                BookmarkPopupView(show: $showBookmarks, manager: bookmarkManager, webView: webView)
            }
        }
    }
    
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

// --- 4. 追蹤 ScrollView 偏移的 PreferenceKey ---
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// --- 5. 書籤彈出視窗介面 ---
struct BookmarkPopupView: View {
    @Binding var show: Bool
    @ObservedObject var manager: BookmarkManager
    let webView: WKWebView
    
    @State private var selectedID: UUID?
    @State private var listScrollY: CGFloat = 0
    @State private var listContentHeight: CGFloat = 0
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            Text("Bookmarks")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(Color(white: 0.3))
            
            // 列表與右側獨立滾動條
            HStack(spacing: 0) {
                // 左側：書籤列表
                ScrollView {
                    VStack(spacing: 0) {
                        // 隱藏的探測器，用來獲取 ScrollView 滑動偏移量
                        GeometryReader { proxy in
                            Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("BookmarkScroll")).minY)
                        }.frame(height: 0)
                        
                        ForEach(manager.bookmarks) { bookmark in
                            Text(bookmark.name)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedID == bookmark.id ? skankRed : Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // 點擊選擇或取消選擇
                                    selectedID = (selectedID == bookmark.id) ? nil : bookmark.id
                                }
                                .onLongPressGesture(minimumDuration: 1.0) {
                                    // 按住 1 秒移除已選項目
                                    if selectedID == bookmark.id {
                                        manager.removeBookmark(bookmark)
                                        selectedID = nil
                                    }
                                }
                        }
                    }
                    .background(GeometryReader { geo in
                        Color.clear.onAppear { listContentHeight = geo.size.height }
                            .onChange(of: geo.size.height) { listContentHeight = $0 }
                    })
                }
                .coordinateSpace(name: "BookmarkScroll")
                .onPreferenceChange(ScrollOffsetKey.self) { y in
                    listScrollY = -y // SwiftUI ScrollView 向下滾動 minY 為負數
                }
                .background(Color(white: 0.15))
                
                // 右側：書籤專屬視覺滾動條
                GeometryReader { geo in
                    let trackHeight = geo.size.height
                    let visibleProp = min(1, trackHeight / max(1, listContentHeight))
                    let thumbHeight = max(20, trackHeight * visibleProp)
                    let maxOffset = trackHeight - thumbHeight
                    let maxScroll = max(0.1, listContentHeight - trackHeight)
                    let currentOffset = maxOffset * min(max(listScrollY / maxScroll, 0), 1)
                    
                    ZStack(alignment: .top) {
                        Color(white: 0.6)
                        skankRed
                            .frame(height: thumbHeight)
                            .offset(y: currentOffset.isNaN ? 0 : currentOffset)
                    }
                }
                .frame(width: 15) // 書籤滾條稍微幼少少
            }
            
            // 底部按鈕 (Cancel / Add... / Go...)
            HStack(spacing: 5) {
                popupButton(title: "Cancel", color: skankRed) {
                    show = false
                }
                popupButton(title: "Add...", color: Color(red: 0.2, green: 0.6, blue: 1.0)) {
                    addCurrentToBookmarks()
                }
                popupButton(title: "Go...", color: Color.green) {
                    goToSelectedBookmark()
                }
            }
            .padding(5)
            .background(Color.white)
        }
        .frame(width: 280, height: 350)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(radius: 10)
    }
    
    // 加入目前網頁
    private func addCurrentToBookmarks() {
        let title = webView.title?.trimmingCharacters(in: .whitespaces) ?? ""
        let absoluteURL = webView.url?.absoluteString ?? ""
        guard !absoluteURL.isEmpty else { return }
        
        var nameToSave = title
        if nameToSave.isEmpty {
            // 利用 Regex 移除 http://, https://, data://, app:// 等前綴
            nameToSave = absoluteURL.replacingOccurrences(of: "^[a-zA-Z]+://", with: "", options: .regularExpression)
        }
        
        manager.addBookmark(name: nameToSave, url: absoluteURL)
    }
    
    // 進入已選擇的書籤
    private func goToSelectedBookmark() {
        guard let id = selectedID,
              let selected = manager.bookmarks.first(where: { $0.id == id }),
              let targetURL = URL(string: selected.url) else { return }
        
        webView.load(URLRequest(url: targetURL))
        show = false
    }
    
    @ViewBuilder
    private func popupButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(color)
                .cornerRadius(6)
        }
    }
}

// --- 6. WKWebView 封裝 ---
struct SkankWebView: UIViewRepresentable {
    let webView: WKWebView
    let url: URL
    @ObservedObject var webViewState: WebViewState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // 綁定 KVO 監聽
        context.coordinator.setupKVO(for: webView.scrollView)
        
        // 讓外部 SwiftUI 可以觸發 WKWebView 的 ScrollView 捲動
        webViewState.setScrollOffset = { [weak webView] yOffset in
            webView?.scrollView.contentOffset.y = yOffset
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: SkankWebView
        var offsetObserver: NSKeyValueObservation?
        var sizeObserver: NSKeyValueObservation?
        
        init(_ parent: SkankWebView) {
            self.parent = parent
        }
        
        func setupKVO(for scrollView: UIScrollView) {
            offsetObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.webViewState.scrollY = view.contentOffset.y
                }
            }
            
            sizeObserver = scrollView.observe(\.contentSize, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.parent.webViewState.contentHeight = view.contentSize.height
                    self?.parent.webViewState.viewHeight = view.bounds.height
                }
            }
        }
        
        deinit {
            offsetObserver?.invalidate()
            sizeObserver?.invalidate()
        }
    }
}
