import SwiftUI
import CoreBluetooth
import Network

// --- 1. 負責監聽系統藍牙同 Wi-Fi 狀態的管理器 ---
class PowerStateManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var isBluetoothOn = false
    @Published var isWifiOn = false
    
    private var cbManager: CBCentralManager!
    private let nwMonitor = NWPathMonitor()
    
    override init() {
        super.init()
        // 初始化藍牙管理器
        cbManager = CBCentralManager(delegate: self, queue: nil)
        
        // 初始化網絡監聽器 (檢測 Wi-Fi 介面是否可用)
        nwMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isWifiOn = path.usesInterfaceType(.wifi)
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        nwMonitor.start(queue: queue)
    }
    
    // 藍牙狀態更新回調
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isBluetoothOn = (central.state == .poweredOn)
        }
    }
}

// --- 2. Power Settings 主介面 ---
struct PowerView: View {
    @Binding var currentApp: AppState
    
    // 綁定系統狀態管理器
    @StateObject private var powerState = PowerStateManager()
    
    // 控制各個功能的開關狀態
    @State private var isLCDOn = true
    @State private var isBacklightOn = true
    @State private var isMultitouchOn = true
    @State private var isAirplaneModeOn = false
    
    // 記錄原本的螢幕亮度，方便復原
    @State private var previousBrightness: CGFloat = UIScreen.main.brightness
    
    // 定義顏色 (參考截圖)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let skankGreen = Color(red: 0.2, green: 0.85, blue: 0.3)
    
    var body: some View {
        ZStack {
            // 背景底色
            Color.black.ignoresSafeArea()
            
            // 介面主體
            VStack(spacing: 15) {
                StatusBarView()
                
                Spacer().frame(height: 10)
                
                // 1. Hibernate H1 chip (紅色，沒有作用)
                powerButton(title: "Hibernate H1 chip", isOn: false) {}
                
                // 2. Bluetooth Power (檢查系統)
                powerButton(title: "Bluetooth Power: \(powerState.isBluetoothOn ? "On" : "Off")", isOn: powerState.isBluetoothOn) {}
                
                // 3. Wifi Power (檢查系統)
                powerButton(title: "Wifi Power: \(powerState.isWifiOn ? "On" : "Off")", isOn: powerState.isWifiOn) {}
                
                // 4. LCD Screen
                powerButton(title: "LCD Screen: \(isLCDOn ? "On" : "Off")", isOn: isLCDOn) {
                    isLCDOn = false
                }
                
                // 5. Backlight
                powerButton(title: "Backlight: \(isBacklightOn ? "On" : "Off")", isOn: isBacklightOn) {
                    if isBacklightOn {
                        // 關閉前先記錄當前亮度，然後調到0
                        previousBrightness = UIScreen.main.brightness
                        UIScreen.main.brightness = 0.0
                        isBacklightOn = false
                    } else {
                        // 復原剛才的亮度
                        UIScreen.main.brightness = previousBrightness
                        isBacklightOn = true
                    }
                }
                
                // 6. Multitouch
                powerButton(title: "Multitouch: \(isMultitouchOn ? "On" : "Off")", isOn: isMultitouchOn) {
                    isMultitouchOn = false
                }
                
                // 7. Airplane Mode (預設關閉，純視覺切換)
                powerButton(title: "Airplane Mode: \(isAirplaneModeOn ? "On" : "Off")", isOn: isAirplaneModeOn) {
                    isAirplaneModeOn.toggle()
                }
                
                Spacer()
                
                // 8. Main Menu 置底按鈕
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Main Menu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 160, height: 40)
                        .background(skankRed)
                        .cornerRadius(10)
                }
                .padding(.bottom, 40)
            }
            
            // --- 特殊行為圖層 (Overlay) ---
            
            // Multitouch 關閉時的遮罩：幾乎透明，但會擋住所有按鈕點擊，長按1秒解除
            if !isMultitouchOn {
                Color.white.opacity(0.001) // 肉眼睇唔到，但會截取觸控
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isMultitouchOn = true
                    }
            }
            
            // LCD Screen 關閉時的遮罩：全黑畫面，覆蓋最上層，長按1秒解除
            if !isLCDOn {
                Color.black
                    .ignoresSafeArea()
                    .onLongPressGesture(minimumDuration: 1.0) {
                        isLCDOn = true
                    }
            }
        }
    }
    
    // 共用的按鈕 UI 元件
    private func powerButton(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(isOn ? skankGreen : skankRed)
                .cornerRadius(10)
        }
        .padding(.horizontal, 25) // 對應截圖中左右的邊距
    }
}
