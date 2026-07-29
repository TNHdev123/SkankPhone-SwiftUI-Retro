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
    
    private func getBookmarksURL() -> URL {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let webDir = docURL.appendingPathComponent("Web")
        
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

// --- 3. 書籤列表滑動狀態 Object (新加入，用於控制清單) ---
class BookmarkListState: ObservableObject {
    @Published var contentHeight: CGFloat = 1
    @Published var viewHeight: CGFloat = 1
    @Published var scrollY: CGFloat = 0
    
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

// --- 4. Web App 主視圖 ---
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
                            Color(white: 0.75)
                            
                            skankRed
                                .frame(height: thumbHeight)
                                .offset(y: currentOffset.isNaN ? 0 : currentOffset)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard maxOffset > 0 else { return }
                                    let dragY = value.location.y - (thumbHeight / 2)
                                    let percentage = min(max(dragY / maxOffset, 0), 1)
                                    let maxScrollY = webViewState.contentHeight - webViewState.viewHeight
                                    
                                    webViewState.setScrollOffset?(percentage * maxScrollY)
                                }
                        )
                    }
                    .frame(width: 25)
                }
                
                // 底部 4 個藍色功能按鈕
                HStack(spacing: 4) {
                    bottomButton(title: "Back") { webView.goBack() }
                    bottomButton(title: "Reload") { webView.reload() }
                    bottomButton(title: "Bookmarks") { showBookmarks = true }
                    bottomButton(title: "Menu") { currentApp = .main }
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

// --- 5. 書籤彈出視窗介面 (直角 + 白色分界線) ---
struct BookmarkPopupView: View {
    @Binding var show: Bool
    @ObservedObject var manager: BookmarkManager
    let webView: WKWebView
    
    @State private var selectedID: UUID?
    @StateObject private var listState = BookmarkListState()
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            Text("Bookmarks")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(Color.black)
            
            Color.white.frame(height: 2) // 白色分界線
            
            // 列表與右側獨立滾動條
            HStack(spacing: 0) {
                // 左側：書籤列表 (使用自訂封裝的 TrackableScrollView)
                TrackableScrollView(state: listState) {
                    VStack(spacing: 0) {
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
                                    selectedID = (selectedID == bookmark.id) ? nil : bookmark.id
                                }
                                .onLongPressGesture(minimumDuration: 1.0) {
                                    if selectedID == bookmark.id {
                                        manager.removeBookmark(bookmark)
                                        selectedID = nil
                                    }
                                }
                        }
                    }
                }
                .background(Color.black) // 列表底色
                
                Color.white.frame(width: 2) // 列表與滾動條之間的白色分界線
                
                // 右側：書籤專屬視覺滾動條 (支援拖曳)
                GeometryReader { geo in
                    let trackHeight = geo.size.height
                    let thumbHeight = max(20, trackHeight * listState.visibleProportion)
                    let maxOffset = trackHeight - thumbHeight
                    let currentOffset = maxOffset * listState.scrollProportion
                    
                    ZStack(alignment: .top) {
                        Color(white: 0.75)
                        skankRed
                            .frame(height: thumbHeight)
                            .offset(y: currentOffset.isNaN ? 0 : currentOffset)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard maxOffset > 0 else { return }
                                let dragY = value.location.y - (thumbHeight / 2)
                                let percentage = min(max(dragY / maxOffset, 0), 1)
                                let maxScrollY = listState.contentHeight - listState.viewHeight
                                listState.setScrollOffset?(percentage * maxScrollY)
                            }
                    )
                }
                .frame(width: 22)
            }
            
            Color.white.frame(height: 2) // 列表與底部按鈕之間的白色分界線
            
            // 底部按鈕區塊
            HStack(spacing: 5) {
                popupButton(title: "Cancel", color: skankRed) { show = false }
                popupButton(title: "Add...", color: Color(red: 0.2, green: 0.6, blue: 1.0)) { addCurrentToBookmarks() }
                popupButton(title: "Go...", color: Color.green) { goToSelectedBookmark() }
            }
            .padding(5)
            .background(Color.black) // 按鈕區底色為黑
        }
        .frame(width: 280, height: 350)
        .background(Color.black)
        .border(Color.white, width: 2) // 外圍直角白色邊框
        .shadow(radius: 10)
    }
    
    private func addCurrentToBookmarks() {
        let title = webView.title?.trimmingCharacters(in: .whitespaces) ?? ""
        let absoluteURL = webView.url?.absoluteString ?? ""
        guard !absoluteURL.isEmpty else { return }
        
        var nameToSave = title
        if nameToSave.isEmpty {
            nameToSave = absoluteURL.replacingOccurrences(of: "^[a-zA-Z]+://", with: "", options: .regularExpression)
        }
        manager.addBookmark(name: nameToSave, url: absoluteURL)
    }
    
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
                .cornerRadius(6) // 只有按鈕保留圓角
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
        
        context.coordinator.setupKVO(for: webView.scrollView)
        
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

// --- 7. 用於書籤列表的 UIScrollView 封裝 (支援外部觸發 Offset) ---
struct TrackableScrollView<Content: View>: UIViewRepresentable {
    let state: BookmarkListState
    let content: () -> Content
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, state: state)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        // 將 SwiftUI View 轉換為 UIKit View
        let host = UIHostingController(rootView: content())
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(host.view)
        
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        context.coordinator.host = host
        context.coordinator.setupKVO(for: scrollView)
        
        // 提供給外層的閉包，用於透過右側滾動條控制列表
        state.setScrollOffset = { [weak scrollView] yOffset in
            scrollView?.contentOffset.y = yOffset
        }
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = content()
    }
    
    class Coordinator: NSObject {
        var parent: TrackableScrollView
        var state: BookmarkListState
        var host: UIHostingController<Content>?
        var offsetObserver: NSKeyValueObservation?
        var sizeObserver: NSKeyValueObservation?
        
        init(_ parent: TrackableScrollView, state: BookmarkListState) {
            self.parent = parent
            self.state = state
        }
        
        func setupKVO(for scrollView: UIScrollView) {
            offsetObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.state.scrollY = view.contentOffset.y
                }
            }
            sizeObserver = scrollView.observe(\.contentSize, options: .new) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.state.contentHeight = view.contentSize.height
                    self?.state.viewHeight = view.bounds.height
                }
            }
        }
        
        deinit {
            offsetObserver?.invalidate()
            sizeObserver?.invalidate()
        }
    }
}
