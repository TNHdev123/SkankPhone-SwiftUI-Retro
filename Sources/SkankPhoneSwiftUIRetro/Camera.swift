import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    @Binding var currentApp: AppState
    @StateObject private var cameraModel = CameraModel()
    
    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            
            // 相機預覽畫面
            CameraPreview(session: cameraModel.session)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            
            // 底部操作區
            VStack(spacing: 15) {
                Button(action: {
                    cameraModel.takeSnapshot()
                }) {
                    Text("Take Snapshot")
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.4))
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(Color(red: 0.2, green: 0.6, blue: 1.0))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    currentApp = .main
                }) {
                    Text("Main Menu")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(Color.red) // 依照截圖使用偏紅/橘色
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            cameraModel.checkPermissionsAndStart()
        }
        .onDisappear {
            cameraModel.session.stopRunning()
        }
    }
}

// UIKit 封裝：相機預覽層
struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

// 相機邏輯控制器
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    
    func checkPermissionsAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.setupCamera() }
                }
            }
        default:
            print("Camera access denied")
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        
        session.addInput(input)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func takeSnapshot() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    // 拍照完成後嘅回調，直接儲檔案
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    // 攞相片嘅 Data
    guard let data = photo.fileDataRepresentation() else { return }
    
    // 1. 取得 Document 目錄路徑
    guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    
    // 2. 設定目標資料夾路徑 Document/Media/Pictures
    let mediaPicturesURL = documentDirectory.appendingPathComponent("Media/Pictures")
    
    // 3. 檢查資料夾存唔存在，如果唔存在就建立佢
    if !FileManager.default.fileExists(atPath: mediaPicturesURL.path) {
        do {
            try FileManager.default.createDirectory(at: mediaPicturesURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("建立資料夾失敗: \(error)")
            return
        }
    }
    
    // 4. 設定檔案名稱 (呢度用目前時間戳作為檔名，避免重覆)
    let fileName = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
    let fileURL = mediaPicturesURL.appendingPathComponent(fileName)
    
    // 5. 將相片 Data 寫入檔案
    do {
        try data.write(to: fileURL)
        print("相片已成功儲存至: \(fileURL.path)")
    } catch {
        print("儲存相片失敗: \(error)")
     }
  }
}
