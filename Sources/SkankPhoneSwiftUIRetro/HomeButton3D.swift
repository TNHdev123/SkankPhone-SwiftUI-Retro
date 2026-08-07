import SwiftUI
import UIKit

// --- HomeButton3D 測試介面 ---
struct HomeButton3DView: View {
    @Binding var currentApp: AppState
    
    // 模式切換：false = 3D Touch, true = Haptic Touch
    @State private var isHapticMode = false
    
    // 顯示結果，預設放喺一個低一點的顯示器
    @State private var resultMessage = "Status: Ready"
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 低一點的結果顯示器 (取代標準狀態列，向下推避開瀏海)
            Text(resultMessage)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.6))
                .padding(.top, 50) // 壓低顯示器
            
            Spacer().frame(height: 30)
            
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
            Picker("Mode", selection: $isHapticMode) {
                Text("3D Touch").tag(false)
                Text("Haptic Touch").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 50)
            
            Spacer()
            
            // 4. 畫面下方中間，剛好放一隻手指大小的白色圓框 (交由底層 UIView 處理真實觸控)
            RealTouchCircleView(isHapticMode: isHapticMode, resultMessage: $resultMessage)
                .frame(width: 70, height: 70)
                .padding(.bottom, 60)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// --- 底層觸控封裝：精準讀取 3D Touch 壓力與 Haptic 邏輯 ---
struct RealTouchCircleView: UIViewRepresentable {
    let isHapticMode: Bool
    @Binding var resultMessage: String
    
    func makeUIView(context: Context) -> TouchCircle {
        let view = TouchCircle()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 3
        return view
    }
    
    func updateUIView(_ uiView: TouchCircle, context: Context) {
        context.coordinator.isHapticMode = isHapticMode
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(resultMessage: $resultMessage)
    }
    
    class Coordinator: NSObject, TouchCircleDelegate {
        var isHapticMode: Bool = false
        @Binding var resultMessage: String
        
        // --- 3D Touch 狀態 ---
        let forceThreshold: CGFloat = 1.5 // 觸發「壓下去」的力度閾值
        var isDeepPressed = false
        var deepPressCount = 0
        var deepPressTimer: Timer?
        var resetDeepPressTimer: Timer?
        
        // --- Haptic Touch 狀態 ---
        let hapticEngageDuration = 0.5 // iOS 觸發 Haptic Touch 的標準按住時間
        var isHapticEngaged = false
        var hasTriggeredVoice = false
        var hapticPressTimer: Timer?
        var hapticVoiceTimer: Timer?
        var hapticSwitchWindowTimer: Timer?
        var waitingForSecondLightTap = false
        
        init(resultMessage: Binding<String>) {
            self._resultMessage = resultMessage
        }
        
        func triggerFeedback() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        
        // MARK: - 觸控事件分發
        func touchesBegan(_ touches: Set<UITouch>) {
            guard let touch = touches.first else { return }
            if isHapticMode {
                handleHapticBegan()
            } else {
                handle3DTouch(touch)
            }
        }
        
        func touchesMoved(_ touches: Set<UITouch>) {
            guard !isHapticMode, let touch = touches.first else { return }
            handle3DTouch(touch)
        }
        
        func touchesEnded(_ touches: Set<UITouch>) {
            if isHapticMode {
                handleHapticEnded()
            } else {
                handle3DTouchLifted()
            }
        }
        
        // MARK: - Haptic Touch 邏輯 (精準按住判斷)
        func handleHapticBegan() {
            if waitingForSecondLightTap {
                // 這是「1秒內的第二次輕點」按下動作
                triggerFeedback()
            } else {
                // 第一次按下，開始計算是否達到 Haptic Touch 「按住」的標準
                isHapticEngaged = false
                hasTriggeredVoice = false
                
                // 1. 檢測是否按住達到 0.5 秒 (觸發 Haptic Touch)
                hapticPressTimer?.invalidate()
                hapticPressTimer = Timer.scheduledTimer(withTimeInterval: hapticEngageDuration, repeats: false) { [weak self] _ in
                    self?.isHapticEngaged = true
                    self?.triggerFeedback() // 「按住」成功時的震動
                }
                
                // 2. 檢測是否按住達到 2 秒 (Voice)
                hapticVoiceTimer?.invalidate()
                hapticVoiceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    guard let self = self, self.isHapticEngaged else { return }
                    self.hasTriggeredVoice = true
                    self.triggerFeedback() // Voice 觸發震動
                    self.resultMessage = "Haptic Touch: Voice"
                }
            }
        }
        
        func handleHapticEnded() {
            // 放手時馬上清除計時器，防止後續觸發
            hapticPressTimer?.invalidate()
            hapticVoiceTimer?.invalidate()
            
            if waitingForSecondLightTap {
                // 完成了「輕點一下的放手」
                triggerFeedback() // 放手也有回饋
                resultMessage = "Haptic Touch: Switch"
                waitingForSecondLightTap = false
                hapticSwitchWindowTimer?.invalidate()
            } else {
                if hasTriggeredVoice {
                    // 如果已經觸發了 Voice，放手就不做任何動作
                    hasTriggeredVoice = false
                } else if isHapticEngaged {
                    // 達到了 Haptic Touch 的按住時間 (超過 0.5 秒)，現在放手
                    triggerFeedback() // 「放手」的回饋
                    resultMessage = "Haptic Touch: Home"
                    
                    // 開啟 0.5 秒內輕點等待視窗
                    waitingForSecondLightTap = true
                    hapticSwitchWindowTimer?.invalidate()
                    hapticSwitchWindowTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                        self?.waitingForSecondLightTap = false
                    }
                }
                // 注意：如果 isHapticEngaged 係 false，代表按住時間少於 0.5 秒 (純輕觸)，系統會直接忽略，符合你要「按住」嘅要求。
            }
            isHapticEngaged = false
        }
        
        // MARK: - 真實 3D Touch 邏輯 (靠壓力 Force)
        func handle3DTouch(_ touch: UITouch) {
            let force = touch.force
            
            if force >= forceThreshold && !isDeepPressed {
                // 壓下去！
                isDeepPressed = true
                triggerFeedback()
                deepPressCount += 1
                
                // 壓住 1 秒檢測 (Voice)
                deepPressTimer?.invalidate()
                deepPressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                    self?.triggerFeedback()
                    self?.resultMessage = "3D Touch: Voice"
                    self?.deepPressCount = 0 // 觸發 Voice 後重置點擊計數
                }
                
            } else if force < forceThreshold - 0.3 && isDeepPressed {
                // 壓上來！(加入少少緩衝避免邊緣抖動)
                process3DTouchRelease()
            }
        }
        
        func handle3DTouchLifted() {
            // 如果手指直接離開螢幕，同時處理釋放邏輯
            if isDeepPressed {
                process3DTouchRelease()
            }
        }
        
        private func process3DTouchRelease() {
            isDeepPressed = false
            triggerFeedback()
            deepPressTimer?.invalidate()
            
            if deepPressCount == 1 {
                resultMessage = "3D Touch: Home"
                // 等待 0.5 秒睇下有冇第二次深壓
                resetDeepPressTimer?.invalidate()
                resetDeepPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    self?.deepPressCount = 0
                }
            } else if deepPressCount >= 2 {
                resultMessage = "3D Touch: Switch"
                deepPressCount = 0
                resetDeepPressTimer?.invalidate()
            }
        }
    }
}

// 攔截並轉發 UITouch 的 UIView
protocol TouchCircleDelegate: AnyObject {
    func touchesBegan(_ touches: Set<UITouch>)
    func touchesMoved(_ touches: Set<UITouch>)
    func touchesEnded(_ touches: Set<UITouch>)
}

class TouchCircle: UIView {
    weak var delegate: TouchCircleDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 確保永遠係一個正圓形
        self.layer.cornerRadius = self.bounds.width / 2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.touchesBegan(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        delegate?.touchesMoved(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        delegate?.touchesEnded(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        delegate?.touchesEnded(touches)
    }
}
