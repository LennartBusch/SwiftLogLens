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
            ForEach(filter(by: category).reversed(), id: \.timestamp){log in
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
                    if LogLensConfig.storeCopyOnWrite{
                        if !viewModel.fetching{
                            Button(action: {
#if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                                viewModel.loadLogs()
                            }, label: {
                                Image(systemName: "arrow.counterclockwise")
                            })
                        }else{
                            ProgressView()
                        }
                        
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
                Text(log.category.rawValue.capitalized)
            }
            Text(log.timestamp.logFormat())
            Divider()
            Text(preview ?  String(log.message.prefix(50)) : log.message)
                .font(.caption)
        }
        .font(.footnote)
    }
    
    func filter(by category: Category?)->[CustomLog]{
        guard let category else{
            return LogLensConfig.storeCopyOnWrite ? viewModel.customLogs : viewModel.logs.compactMap{$0.toCustomLog(type: categoryType)}
        }
        if LogLensConfig.storeCopyOnWrite{
            return viewModel.customLogs.filter{$0.category.rawValue == category.rawValue}
        }else{
            return viewModel.logs.filter{($0 as? OSLogEntryLog)?.category == category.rawValue}.compactMap{$0.toCustomLog(type: categoryType)}
        }
    }
    
    
}


