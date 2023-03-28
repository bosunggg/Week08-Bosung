//
//  CameraManager.swift
//  Week08-Bosung
//
//  Created by Bosung Kim on 3/28/23.
//

import Foundation

class CameraManager: ObservableObject {
    
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    static let shared = CameraManager()
    
    private init() {
        configure()
    }
    private func configure(){
    }
}

@Published var error: CameraError?

let session = AVCaptureSession()

private let sessionQueue = DispatchQueue(label:
"com.raywenderlic.SessionQ")

private let videoPutput = AVCaptureVideoDataOuput ()

private var status = Status.unconfigured

private func set(error: CameraError?) {
    DispatchQueue.main.async {
        self.error = error
    }
}

private func checkPermissions() {
    switch AVCaptureDevice. authorizationStatus(for: .video) {
    case .notDertermined:
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for .video) {authorized in
            if !authorized {
                self.status = .unauthroized
                self.set(error: .deniedAuthorization)
            }
            self.sessionQueue.resume()
        }
    case .resitricted:
        status = .unauthorized
        set(error: .restrictedAuthorization)
    case.denied:
        status = .unauthroized
        set(error: .deniedAuthrorization)
        
    case .authorized;
        break
    @unknown default:
        status = .unauthorized
        set(error: .unknownAuthroziation)
    }
}

private func configureCaptureSession() {
  guard status == .unconfigured else {
    return
  }
  session.beginConfiguration()
  defer {
    session.commitConfiguration()
  }
}

let device = AVCaptureDevice.default(
  .builtInWideAngleCamera,
  for: .video,
  position: .front)
guard let camera = device else {
  set(error: .cameraUnavailable)
  status = .failed
  return
}

do {
  // 1
  let cameraInput = try AVCaptureDeviceInput(device: camera)
  // 2
  if session.canAddInput(cameraInput) {
    session.addInput(cameraInput)
  } else {
    // 3
    set(error: .cannotAddInput)
    status = .failed
    return
  }
} catch {
  // 4
  set(error: .createCaptureInput(error))
  status = .failed
  return
}

if session.canAddOutput(videoOutput) {
  session.addOutput(videoOutput)
  // 2
  videoOutput.videoSettings =
    [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
  // 3
  let videoConnection = videoOutput.connection(with: .video)
  videoConnection?.videoOrientation = .portrait
} else {
  // 4
  set(error: .cannotAddOutput)
  status = .failed
  return
}

status = .configured


checkPermissions()
sessionQueue.async {
  self.configureCaptureSession()
  self.session.startRunning()
}

func set(
  _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
  queue: DispatchQueue
) {
  sessionQueue.async {
    self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
  }
}
