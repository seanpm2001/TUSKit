//
//  UploadsListView.swift
//  TUSKitExample
//
//  Created by Sai Raghu Varma Kallepalli on 15/07/23.
//

import SwiftUI

enum UploadCategory: CaseIterable {
    case all
    case uploaded
    case failed
    case uploading
    case paused
    
    var title: String {
        switch self {
            case .all:          return "All"
            case .uploaded:     return "Uploaded"
            case .failed:       return "Failed"
            case .uploading:    return "Uploading"
            case .paused:       return "Paused"
        }
    }
    
    var noRecoredMessage: String {
        switch self {
            case .all:          return "No upload items\nUpload files for Upload files tab"
            case .uploaded:     return "No uploaded items"
            case .failed:       return "No failed items"
            case .uploading:    return "No active items"
            case .paused:       return "No paused items"
        }
    }
    
    func isSameKind(status: UploadStatus) -> Bool {
        switch self {
            case .all:          return true
            case .uploaded:     if case .uploaded(_) = status { return true }
            case .failed:       if case .failed(_) = status { return true }
            case .uploading:    if case .uploading(_, _) = status { return true }
            case .paused:       if case .paused(_, _) = status { return true }
        }
        return false
    }
}

struct UploadsListView: View {
    
    @EnvironmentObject var tusWrapper: TUSWrapper
    
    // Upload record items
    @State var uploadCategory: UploadCategory = .all
    private var filteredUploads: [UUID: UploadStatus] {
        withAnimation {
            return tusWrapper.uploads.filter { return uploadCategory.isSameKind(status: $0.value) }
        }
    }
    private var uploadRecordsIsEmpty: Bool {
        return filteredUploads.isEmpty
    }
    
    var body: some View {
        VStack {
            if uploadRecordsIsEmpty {
                noUploadRecordsView()
                    .frame(alignment: .center)
            } else {
                uploadRecordsListView(items: filteredUploads)
            }
        }
        .toolbar {
            // TODO: - Remove availability check once target is changed to iOS 15 and above
            if #available(iOS 15.0, *) {
                navBarRightItem()
            }
        }
    }
}


// MARK: - Interface


extension UploadsListView {
    
    
    // MARK: - No Records View
    
    
    @ViewBuilder
    private func noUploadRecordsView() -> some View {
        Spacer()
        Text(uploadCategory.noRecoredMessage)
            .multilineTextAlignment(.center)
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.horizontal, 15)
        Spacer()
    }
    
    
    // MARK: - Records List View
    
    
    @ViewBuilder
    private func uploadRecordsListView(items: [UUID: UploadStatus]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Divider()
                ForEach(Array(items), id: \.key) { idx in
                    Group {
                        switch idx.value {
                            case .uploading(let bytesUploaded, let totalBytes):
                                UploadingRowView(key: idx.key, bytesUploaded: bytesUploaded, totalBytes: totalBytes)
                            case .paused(let bytesUploaded, let totalBytes):
                                PausedRowView(key: idx.key, bytesUploaded: bytesUploaded, totalBytes: totalBytes)
                            case .uploaded(let url):
                                UploadedRowView(key: idx.key, url: url)
                            case .failed(let error):
                                FailedRowView(key: idx.key, error: error)
                        }
                    }
                    Divider()
                }
            }
        }
    }
    
    
    // MARK: - NavBar right item
    
    // TODO: - Remove availability check once target is changed to iOS 15 and above
    @available(iOS 15.0, *)
    @ViewBuilder
    private func navBarRightItem() -> some View {
        let checkmark = "checkmark.circle"
        Menu {
            Section("Filter records") {
                ForEach(UploadCategory.allCases, id: \.self) { kind in
                    Button {
                        uploadCategory = kind
                    } label: {
                        HStack {
                            Text(kind.title)
                            if uploadCategory == kind {
                                Image(systemName: checkmark)
                            }
                        }
                    }
                }
            }
            
            Section("Stop and remove \(uploadCategory.title.lowercased()) records") {
                Button(role: .destructive) {
                    filteredUploads.forEach({ tusWrapper.clearUpload(id: $0.key) })
                } label: {
                    Label("Remove \(uploadCategory.title)", systemImage: Icon.trash.rawValue)
                }
                .disabled(filteredUploads.isEmpty)
            }
        } label: {
            HStack {
                Text(uploadCategory.title)
                Image(systemName: "ellipsis.circle")
            }
            .animation(nil, value: UUID())
        }
    }
}

extension View {
    func rowPadding() -> some View {
        self
            .padding(.vertical, 10)
            .padding(.leading, 5)
            .padding(.trailing, 15)
    }
}
