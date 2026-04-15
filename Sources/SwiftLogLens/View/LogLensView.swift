//
//  File.swift
//  EventLogger
//
//  Created by Lennart Busch on 31.12.24.
//

import Foundation
import SwiftUI
import OSLog

public struct LogLensView<Category: LogCategory>: View {
    private let categoryType: Category.Type
    @StateObject var viewModel = ViewModel()
    @State private var selectedCategoryName: String? = nil
    
    
    public init (categoryType: Category.Type) {
        self.categoryType = categoryType
    }
    
    public var body: some View {
        List{
            ForEach(filter(by: selectedCategoryName, logs: viewModel.customLogs).reversed(), id: \.timestamp){log in
                NavigationLink(destination: {
                    ScrollView{
                        logBody(log: log, preview: false)
                            .padding(.horizontal)
                        
                    }
                }, label: {
                    logBody(log: log, preview: true)
                })
            }
        }
        .refreshable(action: refresh)
        .onAppear(perform: refresh)
        .toolbar{
            ToolbarItemGroup(placement: .primaryAction, content: {
                HStack{
                    Picker("",selection: $selectedCategoryName, content: {
                        Text("All").tag(nil as String?)
                        ForEach(availableCategoryNames, id: \.self) { categoryName in
                            Text(categoryName.capitalized)
                                .foregroundStyle(Color.white)
                                .font(.headline)
                                .padding(.top, -20)
                                .tag(Optional(categoryName))
                        }
                    })
                    .labelsHidden()
                    .tint(.gray)
                    .font(.headline)
                    .foregroundStyle(Color.black)
                    #if os(iOS)
                    .pickerStyle(.automatic)
                    #elseif os(watchOS)
                    .pickerStyle(.navigationLink)
                    #else
                    .pickerStyle(.menu)
                    #endif
                    if !LogLensConfig.storeCopyOnWrite{
                        if !viewModel.fetching{
                            Button(action: {
#if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                                viewModel.loadLogs(for: selectedCategoryName)
                            }, label: {
                                Image(systemName: "arrow.counterclockwise")
                            })
                        }else{
                            ProgressView()
                        }
                    }else{
                        Button(action: {
                            Task{
                                await LogStore.shared.clearLogs()
                                await viewModel.reloadLocalLogs()
                            }
                        }, label: {
                            Image(systemName: "trash.fill")
                        })
                    }
                }

            })
            
        }
        
    }
    
    func logBody(log: CustomLog, preview: Bool)-> some View{
        VStack(alignment: .leading){
            HStack{
                if log.type == .fault || log.type == .error{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                }
                if !log.category.isEmpty {
                    Text(log.category.capitalized)
                }
            }
            Text(log.timestamp.logFormat())
            Divider()
            Text(preview ?  String(log.message.prefix(50)) : log.message)
                .font(.caption)
        }
        .font(.footnote)
    }
    
    private var availableCategoryNames: [String] {
        let declaredCategories = categoryType.allCases.map(\.rawValue)
        let dynamicCategories = viewModel.customLogs
            .map(\.category)
            .filter { !$0.isEmpty }
        return Array(Set(declaredCategories + dynamicCategories))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func filter(by categoryName: String?, logs: [CustomLog])->[CustomLog]{
        guard let categoryName else { return logs }
        return logs.filter { $0.category == categoryName }

    }
    
    
    func refresh(){
        Task{
            if LogLensConfig.storeCopyOnWrite {
                await viewModel.reloadLocalLogs()
            } else {
                await MainActor.run {
                    viewModel.loadLogs(for: selectedCategoryName)
                }
            }
        }
    }
    
}


#Preview {
    if #available(iOS 17.0, *) {
        NavigationStack{
            LogLensView(categoryType: X.self)
//            if let url = LogStore.logURL{
//                ShareLink(item: url)
//            }
        }
    }
}
enum X : String, LogCategory{
    var id: Self { self }
    case loglens
}
