import WidgetKit
import SwiftUI
import ActivityKit
import UIKit

@main
struct CodeBoxWidget: WidgetBundle {
    var body: some Widget {
        CodeBoxLiveActivity()
    }
}

struct CodeBoxLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CodeBoxAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.4)) // Brown box
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.stationName.isEmpty ? "菜鸟驿站" : context.state.stationName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack(spacing: 6) {
                            Text(context.state.platform.isEmpty ? "其他快递" : context.state.platform)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !context.state.reminderText.isEmpty {
                                Text(context.state.reminderText)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                }
                
                Line()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .frame(height: 1)
                    .foregroundColor(.secondary.opacity(0.3))
                
                Text(context.state.pickupCode)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(20)
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.stationName.isEmpty ? "菜鸟驿站" : context.state.stationName)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("取件码:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(context.state.pickupCode)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        if !context.state.reminderText.isEmpty {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.caption2)
                                Text(context.state.reminderText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text("待取件")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } minimal: {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.orange)
            }
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}