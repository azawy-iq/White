import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            // خلفية سوداء مطلقة لملء الشاشة وإلغاء أي حواف سوداء
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    
                    // شريط التنقل العلوي الزجاجي (محمي تماماً أسفل النوتش والجزيرة الديناميكية)
                    HStack {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
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
                            viewModel.exportAIProject()
                            showExportAlert = true
                        }) {
                            Text("AI EXPORT")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                                .foregroundColor(.white)
                        }
                        .alert("التصدير الذكي", isPresented: $showExportAlert) {
                            Button("موافق", role: .cancel) { }
                        } message: {
                            Text(viewModel.exportMessage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(.ultraThinMaterial)

                    // مساحة عرض الفيديو الأساسية (ملء الشاشة بالكامل وبدون حواف)
                    ZStack {
                        if let player = viewModel.currentPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                                .clipped()
                                .edgesIgnoringSafeArea(.horizontal)
                        } else if let image = viewModel.currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                                .clipped()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("اضغط (+) لإضافة مقاطع، وسيقوم الذكاء الاصطناعي بتصميم الفيديو لوحده!")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                            .background(Color(red: 0.03, green: 0.03, blue: 0.03))
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // شريط التايملاين والأدوات
                    VStack(spacing: 8) {
                        // شريط المقاطع المصغرة
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 70, height: 45)
                                            .overlay(
                                                Text("مقطع \(index + 1)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )

                                        Button(action: { viewModel.removeMedia(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                    .onTapGesture { viewModel.playMedia(at: index) }
                                }

                                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
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

                        // شريط الأدوات الزجاجي السفلي (مفعل بالكامل)
                        HStack(spacing: 14) {
                            ToolButton(icon: "scissors", label: "القص والمدة") { viewModel.activeTool = .duration }
                            ToolButton(icon: "wand.and.rays", label: "العزل والفلتر") { viewModel.toggleIsolation() }
                            ToolButton(icon: "textformat", label: "الخطوط والكلام") { viewModel.activeTool = .lyrics }
                            ToolButton(icon: "waveform", label: "استخراج الصوت") { viewModel.extractAudio() }
                            ToolButton(icon: "sparkles", label: "تصميم ذكي AI") { viewModel.aiAutoEditAndSync() }
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

struct ToolButton: View {
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
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hdExport") var hdExport = true

    var body: some View {
        NavigationView {
            Form {
                Toggle("تصدير بجودة عالية (HD)", isOn: $hdExport)
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("تم") { dismiss() } }
        }
    }
}
