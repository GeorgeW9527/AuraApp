//
//  CameraView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import AVFoundation
import Combine
import ImageIO
import SwiftUI
import UIKit

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    var onImageCaptured: () -> Void

    @StateObject private var camera = CameraManager()
    @State private var isCapturing = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            cameraOverlay

            if isCapturing {
                captureOverlay
            }

            if let errorMessage = camera.errorMessage {
                errorBanner(errorMessage)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .task {
            let granted = await camera.prepareIfNeeded()
            if !granted {
                showPermissionAlert = true
            }
        }
        .onDisappear {
            camera.stopSession()
        }
        .alert("Camera Access Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
                dismiss()
            }
            Button("Not Now", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please allow camera access in Settings so Aura can photograph your meals.")
        }
    }

    private var cameraOverlay: some View {
        VStack(spacing: 0) {
            topBar

            Spacer()

            focusGuide

            Spacer()

            bottomControls
        }
    }

    private var topBar: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.black.opacity(0.78), Color.black.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 190)
            .ignoresSafeArea(edges: .top)

            HStack(alignment: .top) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.32), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                }

                Spacer()

                VStack(spacing: 6) {
                    Text("Capture Your Meal")
                        .font(.system(size: 22, weight: .bold))
                    Text("Center the food for faster AI analysis")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                statusChip(
                    icon: "sparkles",
                    title: "AI Ready",
                    tint: Color(red: 0.75, green: 0.42, blue: 1.0)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
    }

    private var focusGuide: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.85), .white.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.6, dash: [10, 8])
                )
                .frame(width: 292, height: 360)
                .background(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.white.opacity(0.05))
                )

            VStack(spacing: 10) {
                statusChip(
                    icon: "fork.knife.circle.fill",
                    title: "Best Angle",
                    tint: Color(red: 0.35, green: 0.82, blue: 0.54)
                )

                Text("Keep the dish fully inside the frame")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 32)
    }

    private var bottomControls: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.black.opacity(0.04), Color.black.opacity(0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 20) {
                HStack(spacing: 10) {
                    infoPill(icon: "leaf.fill", title: "Natural light helps")
                    infoPill(icon: "scope", title: "One main dish per shot")
                }

                HStack(alignment: .center) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(.white.opacity(0.12), in: Circle())
                    }

                    Spacer()

                    Button(action: capturePhoto) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.95),
                                            Color(red: 0.94, green: 0.95, blue: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 84, height: 84)

                            Circle()
                                .stroke(Color.white.opacity(0.36), lineWidth: 6)
                                .frame(width: 98, height: 98)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.29, green: 0.75, blue: 0.54),
                                            Color(red: 0.24, green: 0.50, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 18, height: 18)
                                .offset(y: 28)
                        }
                    }
                    .disabled(isCapturing || !camera.isCaptureReady)

                    Spacer()

                    Button(action: { camera.toggleCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .disabled(isCapturing || !camera.isCaptureReady)
                }

                Text(camera.isCaptureReady ? "Tap to capture, then Aura will estimate calories and macros." : "Preparing camera...")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
    }

    private var captureOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Capturing photo...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .transition(.opacity)
    }

    private func statusChip(icon: String, title: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.88), tint.opacity(0.52)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
    }

    private func infoPill(icon: String, title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.1), in: Capsule())
    }

    private func errorBanner(_ message: String) -> some View {
        VStack {
            Spacer()

            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.88), in: Capsule())
                .padding(.bottom, 148)
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }

    private func capturePhoto() {
        guard !isCapturing, camera.isCaptureReady else { return }
        isCapturing = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        camera.capturePhoto { result in
            DispatchQueue.main.async {
                isCapturing = false

                switch result {
                case .success(let uiImage):
                    image = uiImage
                    dismiss()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        onImageCaptured()
                    }

                case .failure(let error):
                    camera.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var errorMessage: String?
    @Published var isCaptureReady = false

    private let sessionQueue = DispatchQueue(label: "aura.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private var captureCompletion: ((Result<UIImage, Error>) -> Void)?

    func prepareIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded()
            startSession()
            return true

        case .notDetermined:
            let granted = await requestCameraAccess()
            if granted {
                configureSessionIfNeeded()
                startSession()
            }
            return granted

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    func startSession() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
            self.publishReadiness()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            self.publishReadiness()
        }
    }

    func toggleCamera() {
        sessionQueue.async {
            guard let currentInput = self.currentInput else { return }
            let nextPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            self.configureSession(position: nextPosition)
            self.startSession()
        }
    }

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        sessionQueue.async {
            guard self.isCaptureOperationSafe else {
                completion(.failure(CameraError.notReady))
                return
            }

            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            settings.isHighResolutionPhotoEnabled = false
            settings.photoQualityPrioritization = .balanced

            if let device = self.currentInput?.device, device.hasFlash {
                settings.flashMode = .auto
            }

            self.captureCompletion = completion
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureSessionIfNeeded() {
        sessionQueue.async {
            guard !self.isConfigured else { return }
            self.configureSession(position: .back)
        }
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let currentInput {
            session.removeInput(currentInput)
            self.currentInput = nil
        }

        if session.outputs.contains(photoOutput) == false, session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        do {
            guard let device = bestDevice(for: position) else {
                throw CameraError.unavailable
            }

            let input = try AVCaptureDeviceInput(device: device)

            guard session.canAddInput(input) else {
                throw CameraError.unavailable
            }

            session.addInput(input)
            currentInput = input
            isConfigured = true
            publishError(nil)
        } catch {
            publishError(error.localizedDescription)
            isConfigured = false
        }

        session.commitConfiguration()
        publishReadiness()
    }

    private func bestDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInDualWideCamera,
            .builtInWideAngleCamera
        ]

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )

        return discovery.devices.first
    }

    private func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private var isCaptureOperationSafe: Bool {
        guard isConfigured, session.isRunning else { return false }
        guard let connection = photoOutput.connection(with: .video) else { return false }
        return connection.isActive && connection.isEnabled
    }

    private func publishReadiness() {
        let ready = isCaptureOperationSafe
        DispatchQueue.main.async {
            self.isCaptureReady = ready
        }
    }

    private func publishError(_ message: String?) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            captureCompletion?(.failure(error))
            captureCompletion = nil
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            captureCompletion?(.failure(CameraError.processingFailed))
            captureCompletion = nil
            return
        }

        guard let image = downsampledImage(from: data, maxPixelSize: 2048) else {
            captureCompletion?(.failure(CameraError.processingFailed))
            captureCompletion = nil
            return
        }

        captureCompletion?(.success(image))
        captureCompletion = nil
    }

    private func downsampledImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private enum CameraError: LocalizedError {
    case unavailable
    case notReady
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Camera is unavailable on this device."
        case .notReady:
            return "Camera is still getting ready. Please try again."
        case .processingFailed:
            return "Aura couldn't process the captured photo."
        }
    }
}
