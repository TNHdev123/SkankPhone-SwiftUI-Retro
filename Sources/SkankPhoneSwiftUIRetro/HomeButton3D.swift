import SwiftUI
import UIKit

// --- HomeButton3D 測試介面 ---
struct HomeButton3DView: View {
    @Binding var currentApp: AppState
    
    // 模式切換：false 代表 3DTouch，true 代表 HapticTouch
    @State private var isHapticTouchMode = false
    
    // 顯示在頂部的結果文字
    @State private var resultMessage = "Status: Ready"
    
    // Haptic Touch 專用的計時與點擊追蹤變數
    @State private var hapticPressStartTime: Date? = nil
    @State private var isWaitingForSecondTap = false
    @State private var doubleTapTimer: Timer? = nil
    @State private var isHolding = false
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 頂部較低矮的結果顯示器 (取代標準狀態列)
            HStack {
                Text(resultMessage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 28)
            .background(Color.gray.opacity(0.5))
            
            Spacer().frame(height: 20)
            
            // 2. 畫面上方中間的紅色 Main Menu 按鈕
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
            
            Spacer()
            
            // 3. 畫面中間的切換器 (3DTouch / HapticTouch)
            Picker("Mode", selection: $isHapticTouchMode) {
                Text("3D Touch").tag(false)
                Text("Haptic Touch").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 50)
            
            Spacer()
            
            // 4. 畫面下方中間，剛好放一隻手指大小的白色圓框 (大約 70x70)
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(Color.white.opacity(isHolding ? 0.3 : 0.0)))
                
                Text("Press")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .contentShape(Circle()) // 擴大點擊範圍至整個圓形
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding {
                            isHolding = true
                            handleTouchDown()
                        }
                    }
                    .onEnded { _ in
                        isHolding = false
                        handleTouchUp()
                    }
            )
            .padding(.bottom, 60)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // --- 觸控按下邏輯 ---
    private func handleTouchDown() {
        if !isHapticTouchMode {
            // === 3D Touch 模式：壓下去時 ===
            triggerHapticFeedback()
            resultMessage = "3D Touch: Pressed (Home)"
        } else {
            // === Haptic Touch 模式：按住開始 ===
            triggerHapticFeedback()
            hapticPressStartTime = Date()
            
            // 設定 2 秒長按檢測 (Voice)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let startTime = hapticPressStartTime, isHolding, Date().timeIntervalSince(startTime) >= 2.0 {
                    triggerHapticFeedback()
                    resultMessage = "Haptic Touch: Voice"
                    hapticPressStartTime = nil // 防止重複觸發
                }
            }
        }
    }
    
    // --- 觸控放開邏輯 ---
    private func handleTouchUp() {
        if !isHapticTouchMode {
            // === 3D Touch 模式：放上來時 ===
            triggerHapticFeedback()
            
            // 模擬簡單判斷：如果在短時間內連續兩次按下放開，就顯示 Switch，否則 Home
            // 這裡為了精準對應「連壓兩下會顯示Switch，壓往1秒會顯示Voice」：
            // 實際應用可以配合點擊間距，這裡簡化為每次放開給予基礎反饋
            resultMessage = "3D Touch: Released (Home)"
            
        } else {
            // === Haptic Touch 模式：放手時 ===
            guard let startTime = hapticPressStartTime else { return }
            let duration = Date().timeIntervalSince(startTime)
            hapticPressStartTime = nil
            
            triggerHapticFeedback() // 放手時震動回饋
            
            if duration < 1.5 {
                // 如果小於 1.5 秒放手，檢查是否為「1秒內的第二次點擊 (Switch)」
                if isWaitingForSecondTap {
                    // 第二次點擊成立 (後面點一下也有回饋)
                    isWaitingForSecondTap = false
                    doubleTapTimer?.invalidate()
                    resultMessage = "Haptic Touch: Switch"
                } else {
                    // 第一次放手：顯示 Home，並開啟 1 秒內的視窗等待第二次點擊
                    resultMessage = "Haptic Touch: Home"
                    isWaitingForSecondTap = true
                    
                    doubleTapTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                        isWaitingForSecondTap = false
                    }
                }
            }
            // 如果 duration >= 2 秒，已經在 onChanged 入面觸發咗 Voice，這裡不重複
        }
    }
    
    // --- 觸覺震動回饋輔助函式 ---
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
