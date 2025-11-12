//
//  MainView.swift
//  FaceFXKit
//
//  Created by Vladislav Markov on 11/07/2025.
//

import SwiftUI
import PhotosUI

struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var imageSelection: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FaceFX Kit")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select a photo to start editing")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                        .opacity(viewModel.isLoading ? 1 : 0)
                }
                
                Spacer()
                
                PhotosPicker(
                    selection: $imageSelection,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text("Select Photo from Gallery")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 64)
                .onChange(of: imageSelection) { _, newValue in
                    if let newValue {
                        Task {
                            await viewModel.selectPhotoFromGallery(item: newValue)
                            imageSelection = nil
                        }
                    }
                }
            }
            .navigationTitle("FaceFX Kit")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.showingEditor) {
                if let photo = viewModel.selectedPhoto {
                    EditorView(photo: photo)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
