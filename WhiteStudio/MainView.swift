import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    
                    // شريط التنقل العلوي
                    HStack {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .sheet(isPresented: $showSettings) {
                            SettingsView()
                        }

                        Spacer()

                        Text("WHITE STUDIO")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            viewModel.exportProject()
                            showExportAlert = true
                        }) {
                            Text("EXPORT")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.white)
                        }
                        .alert("الحالة", isPresented: $showExportAlert) {
                            Button("موافق", role: .cancel) { }
                        } message: {
                            Text(viewModel.statusMessage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(.ultraThinMaterial)

                    // عرض الفيديو أو الصورة
                    ZStack {
                        if let player = viewModel.currentPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.60)
                                .clipped()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles.tv")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.4))
                                Text(viewModel.statusMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.60)
                            .background(Color(red: 0.03, green: 0.03, blue: 0.03))
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // شريط التايملاين والأدوات الحقيقية
                    VStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.clips.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 70, height: 45)
                                            .overlay(
                                                Text("فيديو \(index + 1)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )

                                        Button(action: { viewModel.removeClip(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }

                                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos])) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 70, height: 45)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        )
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16))
                                        )
                                }
                                .onChange(of: viewModel.selectedItem) { newItem in
                                    Task { await viewModel.loadMedia(from: newItem) }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .frame(height: 50)

                        // الأدوات الحقيقية المتصلة بالمنطق
                        HStack(spacing: 12) {
                            ToolBtn(icon: "waveform", label: "استخراج الصوت") { viewModel.extractAudioFromVideo() }
                            ToolBtn(icon: "wand.and.rays", label: "عزل الخلفية") { viewModel.applyBackgroundIsolation() }
                            ToolBtn(icon: "sparkles", label: "مزامنة ذكية") { viewModel.autoGenerateLyricsAndDialect() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

struct ToolBtn: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            Form {
                Text("إعدادات تطبيق White Studio الاحترافي")
            }
            .navigationTitle("الإعدادات")
            .toolbar { Button("تم") { dismiss() } }
        }
    }
}
