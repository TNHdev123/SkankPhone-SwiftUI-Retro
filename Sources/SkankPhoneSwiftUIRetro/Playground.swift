import SwiftUI
import CoreMotion
import AVFoundation

// --- 1. Playground 主選單介面 ---
struct PlaygroundView: View {
    @Binding var currentApp: AppState
    
    @State private var showAccelerometer = false
    @State private var showTileGame = false
    @State private var showMissionControl = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        ZStack {
            if showAccelerometer {
                AccelerometerView(showAccelerometer: $showAccelerometer)
            } else if showTileGame {
                TileGameView(currentApp: $currentApp)
            } else if showMissionControl {
                MissionControlView(currentApp: $currentApp)
            } else {
                // 主介面
                VStack(spacing: 0) {
                    StatusBarView()
                    
                    Spacer().frame(height: 30)
                    
                    VStack(spacing: 12) {
                        playgroundButton(title: "Tracker") {}
                        playgroundButton(title: "Accelerometer") { showAccelerometer = true }
                        playgroundButton(title: "Tile Game") { showTileGame = true }
                        playgroundButton(title: "Mission: Control") { showMissionControl = true }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Main Menu 置底按鈕
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
                    .padding(.bottom, 40)
                }
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
    
    private func playgroundButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
}


// --- 2. Accelerometer (陀螺儀) 介面 ---
struct AccelerometerView: View {
    @Binding var showAccelerometer: Bool
    @StateObject private var motion = MotionManager()
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部數值列 (取代狀態列)
            HStack {
                Text(String(format: "x: %.2f", motion.x))
                    .foregroundColor(Color.green.opacity(0.8))
                Spacer()
                Text(String(format: "y: %.2f", motion.y))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "z: %.2f", motion.z))
                    .foregroundColor(.white)
                Spacer()
                Text("6:14") // 模擬截圖中嘅時間
                    .foregroundColor(.white)
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.top, 40) // 預留安全區
            .padding(.bottom, 5)
            .background(Color.gray.opacity(0.4))
            
            // Reset 按鈕
            Button(action: {
                motion.reset()
            }) {
                Text("Reset")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(skankRed)
                    .cornerRadius(6)
            }
            .padding(.top, 5)
            
            Spacer()
            
            // 藍色大正方形框與紅點
            ZStack {
                Rectangle()
                    .stroke(skankBlue, lineWidth: 4)
                    .frame(width: 300, height: 300)
                
                Circle()
                    .fill(skankRed)
                    .frame(width: 30, height: 30)
                    .offset(x: motion.dotX, y: motion.dotY)
            }
            
            Spacer()
            
            // Back 按鈕 (返回 Playground 選單)
            Button(action: {
                showAccelerometer = false
            }) {
                Text("Back")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 160, height: 40)
                    .background(skankRed)
                    .cornerRadius(8)
            }
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

// 陀螺儀數據處理邏輯
class MotionManager: ObservableObject {
    private var manager = CMMotionManager()
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    
    // 紅點位移
    @Published var dotX: CGFloat = 0.0
    @Published var dotY: CGFloat = 0.0
    
    func start() {
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 1.0 / 60.0
            manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                self.x = data.acceleration.x
                self.y = data.acceleration.y
                self.z = data.acceleration.z
                
                // 根據加速度更新位置，135係框邊界 (300/2 - 30/2)
                let newX = self.dotX + CGFloat(data.acceleration.x * 15)
                let newY = self.dotY - CGFloat(data.acceleration.y * 15) // y軸反轉以符合現實傾斜
                
                self.dotX = max(min(newX, 135), -135)
                self.dotY = max(min(newY, 135), -135)
            }
        }
    }
    
    func stop() {
        manager.stopAccelerometerUpdates()
    }
    
    func reset() {
        dotX = 0
        dotY = 0
    }
}


// --- 3. Tile Game (相機) 介面 ---
struct TileGameView: View {
    @Binding var currentApp: AppState
    @StateObject private var camera = CameraModel()
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 上半部：相機畫面
                CameraPreview(camera: camera)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                
                // 下半部：控制面板
                HStack(spacing: 20) {
                    // 灰色方格 (顯示相片)
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.8))
                            .frame(width: 80, height: 80)
                        
                        if let image = camera.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                        }
                    }
                    .padding(.leading, 30)
                    
                    // Set Image / Clear Image 按鈕
                    Button(action: {
                        if camera.capturedImage == nil {
                            camera.capture()
                        } else {
                            camera.capturedImage = nil
                        }
                    }) {
                        Text(camera.capturedImage == nil ? "Set Image" : "Clear Image")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(skankBlue)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 30)
                }
                .frame(height: 120)
                .background(Color.black)
            }
        }
        // 長按 1 秒直接退回 Main Menu
        .onLongPressGesture(minimumDuration: 1.0) {
            currentApp = .main
        }
        .onAppear { camera.check() }
        .onDisappear { camera.stop() }
    }
}

// 相機控制邏輯
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    private let output = AVCapturePhotoOutput()
    
    func check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setup()
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { granted in if granted { self.setup() } }
        default: break
        }
    }
    
    private func setup() {
        DispatchQueue.global(qos: .background).async {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            self.session.beginConfiguration()
            if self.session.canAddInput(input) { self.session.addInput(input) }
            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    func stop() {
        session.stopRunning()
    }
    
    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}

// 將 AVFoundation 的畫面橋接入 SwiftUI
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // 確保 Layer 大小跟隨 View
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}


// --- 4. Mission: Control 橫向介面 ---
struct MissionControlView: View {
    @Binding var currentApp: AppState
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 橫向排版主體
                HStack(spacing: 0) {
                    // 左側：控制面板圖案 + 方向鍵
                    ZStack {
                        // 模擬截圖中嘅圖案 (用圓圈與文字代替畫圖)
                        VStack(spacing: 10) {
                            ZStack {
                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 60)
                                Circle().stroke(Color.white, lineWidth: 1).frame(width: 40)
                                Image(systemName: "play.fill").foregroundColor(.white).rotationEffect(.degrees(-90))
                            }
                            Circle().stroke(Color.white, lineWidth: 1).frame(width: 40)
                                .overlay(Text("Option").font(.system(size: 8)).foregroundColor(.white))
                        }
                        .position(x: 80, y: 100)
                        
                        // 四個方向鍵
                        VStack(spacing: 40) {
                            Image(systemName: "triangle.fill").foregroundColor(.gray) // 上
                            HStack(spacing: 80) {
                                Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(-90)) // 左
                                Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(90))  // 右
                            }
                            Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(180)) // 下
                        }
                        .position(x: 200, y: geo.size.height / 2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右側：連線表單
                    VStack(spacing: 0) {
                        Text("192.168.1.7")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .frame(width: 120, height: 35)
                            .background(Color.white)
                        
                        Button(action: {}) {
                            Text("Connect")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 35)
                                .background(skankBlue)
                        }
                        
                        // Quit 按鈕 (直接返回主頁)
                        Button(action: {
                            currentApp = .main
                        }) {
                            Text("Quit")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 35)
                                .background(skankBlue)
                        }
                    }
                    .border(Color.white, width: 2)
                    .padding(.trailing, 40)
                }
            }
            // 利用旋轉來製造橫向介面效果
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(90))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
