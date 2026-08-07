import SwiftUI

// --- PurpleBoard 測試介面 ---
struct PurpleView: View {
    @Binding var currentApp: AppState
    
    // 頁面狀態，支援 -1, 0, 1
    @State private var currentPage: Int = 0
    
    // 動畫狀態控制
    @State private var isAnimating = false
    @State private var animProgress: CGFloat = 0.0
    
    // 共用顏色
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        ZStack {
            // 1. 背景全黑
            Color.black.ignoresSafeArea()
            
            // 2. 頁面滑動區 (跟隨手勢滑動)
            TabView(selection: $currentPage) {
                // 第 -1 頁
                Color.clear
                    .tag(-1)
                
                // 第 0 頁
                Color.clear
                    .tag(0)
                
                // 第 1 頁 (第一頁)：包含藍色 Open 按鈕
                ZStack {
                    Button(action: {
                        startOpenAnimation()
                    }) {
                        Text("Open")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(skankBlue)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 隱藏預設的頁數小圓點
            
            // 3. 固定的 UI 層 (不隨頁面滑動)
            VStack {
                // 頂部：頁面顯示器
                Text("Page: \(currentPage)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40) // 確保喺原本狀態列之下
                
                Spacer()
                
                // 底部：紅色主頁按鈕
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
                .padding(.bottom, 50)
            }
            
            // 4. 全螢幕動畫層 (處於最頂層)
            if isAnimating {
                GeometryReader { geo in
                    Rectangle()
                        // 初始透明度為 0.5 (半透明)，放大至全螢幕時變為 1.0 (全不透明)
                        .fill(Color.white.opacity(0.5 + 0.5 * animProgress))
                        // 確保比例與螢幕完全一致
                        .frame(width: geo.size.width, height: geo.size.height)
                        // 從縮小的狀態 (例如 0.2 倍) 放大到 1.0 倍
                        .scaleEffect(0.2 + 0.8 * animProgress)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .ignoresSafeArea()
                // 動畫期間阻擋後方所有操作
                .allowsHitTesting(true)
            }
        }
        // 完全隱藏狀態列
        .statusBarHidden(true)
    }
    
    // --- 觸發 Open 動畫邏輯 ---
    private func startOpenAnimation() {
        guard !isAnimating else { return } // 避免重複點擊
        
        // 顯示方形，設定初始進度為 0
        isAnimating = true
        animProgress = 0.0
        
        // 執行 0.5 秒動畫，進度推至 1.0 (填滿畫面 + 全白)
        withAnimation(.easeInOut(duration: 0.5)) {
            animProgress = 1.0
        }
        
        // 0.5 秒動畫 + 1.0 秒全螢幕停留 = 1.5 秒後瞬間消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnimating = false
            animProgress = 0.0 // 重置以備下次使用
        }
    }
}
