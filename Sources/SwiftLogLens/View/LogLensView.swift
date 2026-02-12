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
    @State var category: Category? = nil
    
    
    public init (categoryType: Category.Type) {
        self.categoryType = categoryType
    }
    
    public var body: some View {
        List{
            ForEach(filter(by: category, logs: viewModel.customLogs).reversed(), id: \.timestamp){log in
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
                    Picker("",selection: $category, content: {
                        Text("All").tag(nil as Category?)
                        ForEach(Array(categoryType.allCases)){category in
                            Text(category.rawValue.capitalized)
                                .foregroundStyle(Color.white)
                                .font(.headline)
                                .padding(.top, -20)
                                .tag(category)
                        }
                    })
                    .labelsHidden()
                    .tint(.gray)
                    .font(.headline)
                    .foregroundStyle(Color.black)
                    #if os(iOS)
                    .pickerStyle(.automatic)
                    #else
                    .pickerStyle(.navigationLink)
                    #endif
                    if !LogLensConfig.storeCopyOnWrite{
                        if !viewModel.fetching{
                            Button(action: {
#if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                                viewModel.loadLogs(for: category, as: categoryType)
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
                if let category = log.category{
                    Text(category.rawValue.capitalized)
                }
            }
            Text(log.timestamp.logFormat())
            Divider()
            Text(preview ?  String(log.message.prefix(50)) : log.message)
                .font(.caption)
        }
        .font(.footnote)
    }
    
    func filter(by category: Category?, logs: [CustomLog])->[CustomLog]{
        guard let category else{ return logs}
        return viewModel.customLogs.filter{$0.category?.rawValue == category.rawValue}

    }
    
    
    func refresh(){
        Task{
            await viewModel.reloadLocalLogs()
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
