import SwiftUI
import SwiftData
import SpriteKit
import CoreMotion

class JarPhysicsScene: SKScene {
    private var motionManager = CMMotionManager()
    private var isSetup = false
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        
        // Ensure the scene size perfectly matches the frame
        self.scaleMode = .resizeFill
        
        // Physics edge loop so items don't fall off
        // Note: Using a slightly smaller frame to keep them well inside the visual jar
        let edgeRect = CGRect(x: 10, y: 10, width: self.size.width - 20, height: self.size.height - 20)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: edgeRect)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                // Multiply gravity vectors to make drops more responsive
                self.physicsWorld.gravity = CGVector(dx: data.gravity.x * 15, dy: data.gravity.y * 15)
            }
        }
    }
    
    func setupDrops(count: Int) {
        guard !isSetup else { return }
        isSetup = true
        self.removeAllChildren()
        
        let dropCount = min(count, 100)
        let radius: CGFloat = 12
        
        for i in 0..<dropCount {
            let isBlue = (i % 3 == 0)
            let color = isBlue ? UIColor.systemBlue : UIColor.systemOrange
            let iconName = isBlue ? "bird.fill" : "shippingbox.fill"
            
            if let texture = createDropTexture(color: color, iconName: iconName, radius: radius) {
                let sprite = SKSpriteNode(texture: texture)
                
                // Add some randomness to mass and bounciness to make it look organic
                let randomFactor = CGFloat.random(in: 0.8...1.2)
                sprite.size = CGSize(width: radius * 2 * randomFactor, height: radius * 2 * randomFactor)
                
                // Physics body based on actual texture size
                let physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
                physicsBody.isDynamic = true
                physicsBody.allowsRotation = true
                physicsBody.restitution = 0.4 // Bounciness
                physicsBody.friction = 0.2
                physicsBody.mass = 1.0 * randomFactor
                sprite.physicsBody = physicsBody
                
                // Random start position within bounds
                let x = CGFloat.random(in: 20...(self.size.width - 20))
                let y = CGFloat.random(in: 20...(self.size.height - 20))
                sprite.position = CGPoint(x: x, y: y)
                
                self.addChild(sprite)
            }
        }
    }
    
    private func createDropTexture(color: UIColor, iconName: String, radius: CGFloat) -> SKTexture? {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Draw background circle
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // Draw icon
            let config = UIImage.SymbolConfiguration(pointSize: radius * 1.2, weight: .bold)
            if let icon = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let rect = CGRect(
                    x: (size.width - icon.size.width) / 2,
                    y: (size.height - icon.size.height) / 2,
                    width: icon.size.width,
                    height: icon.size.height
                )
                icon.draw(in: rect)
            }
        }
        return SKTexture(image: image)
    }
}

struct StatisticsView: View {
    @Query private var allItems: [ClipboardItem]
    
    // Calculated statistics
    private var totalItems: Int {
        allItems.count
    }
    
    private var totalPickupCodes: Int {
        allItems.filter { $0.type == .pickupCode }.count
    }
    
    private var totalVerifications: Int {
        allItems.filter { $0.type == .verificationCode }.count
    }
    
    private var totalOthers: Int {
        allItems.filter { $0.type == .other }.count
    }
    
    private var itemsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return allItems.filter {
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var averageItemsPerWeek: Double {
        if allItems.isEmpty { return 0 }
        guard let firstDate = allItems.map({ $0.createdAt }).min() else { return 0 }
        let now = Date()
        let weeks = max(1.0, now.timeIntervalSince(firstDate) / (86400 * 7))
        return Double(allItems.count) / weeks
    }
    
    private var platformStats: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in allItems {
            let platform: String
            if item.type == .pickupCode {
                platform = item.sourcePlatform ?? "未知物流"
            } else if item.type == .verificationCode {
                platform = "验证码短信"
            } else {
                platform = "其他"
            }
            counts[platform, default: 0] += 1
        }
        return counts.map { (name: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
    
    // For the Jar Animation
    @State private var jarScene = JarPhysicsScene(size: CGSize(width: 330, height: 210))
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // The "Jar" illustration
                    jarView
                        .padding(.top, 10)
                    
                    Text("快件统计")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Grid of stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Total Packages
                        StatCardView(
                            title: "累计内容",
                            value: "\(totalItems)",
                            icon: "doc.on.doc.fill",
                            iconColor: .orange
                        )
                        
                        // This Month
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(itemsThisMonth)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text("本月新增")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            ZStack {
                                LinearGradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.4), Color(red: 0.1, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom)
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.yellow)
                                            .padding(6)
                                            .offset(x: -10, y: -5)
                                    }
                                    Spacer()
                                }
                            }
                        )
                        .cornerRadius(20)
                        
                        // Pickups
                        StatCardView(
                            title: "取件码",
                            value: "\(totalPickupCodes)",
                            icon: "shippingbox.fill",
                            iconColor: .green
                        )
                        
                        // Verifications
                        StatCardView(
                            title: "验证码",
                            value: "\(totalVerifications)",
                            icon: "lock.shield.fill",
                            iconColor: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // Top Platforms List
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image(systemName: "rosette")
                            Text("最常取件")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                        
                        ForEach(Array(platformStats.prefix(3).enumerated()), id: \.element.name) { index, stat in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .frame(width: 24, alignment: .leading)
                                Text(stat.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("x\(stat.count)")
                                    .font(.subheadline)
                                    .italic()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if platformStats.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Trend section
                    VStack(alignment: .leading) {
                        Text("新增趋势")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.orange)
                                    Text("新增趋势")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 0) {
                                    Text("\(Calendar.current.component(.month, from: Date()))月，共新增")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(" \(itemsThisMonth)项 ✨")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Simple bar chart
                            HStack(alignment: .bottom, spacing: 12) {
                                VStack {
                                    Text("\(itemsThisMonth)")
                                        .font(.caption2)
                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: 30, height: max(10, min(80, CGFloat(itemsThisMonth) * 10)))
                                        .cornerRadius(6)
                                    Text("\(Calendar.current.component(.month, from: Date()))月")
                                        .font(.caption2)
                                }
                            }
                            .padding(.trailing, 10)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                jarScene.setupDrops(count: totalItems)
            }
            .onChange(of: totalItems) { oldValue, newValue in
                jarScene.setupDrops(count: newValue)
            }
        }
    }
    
    private var jarView: some View {
        VStack(spacing: 0) {
            // Jar lid
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(colors: [
                    Color(white: 0.9), // Highlight on top edge
                    Color(white: 0.7), // Mid tone
                    Color(white: 0.5)  // Shadow on bottom edge
                ], startPoint: .top, endPoint: .bottom))
                .frame(width: 320, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: -3) // Top shadow
                .zIndex(1)
            
            // Jar body
            ZStack(alignment: .bottom) {
                // Glass background
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 350, height: 230)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    // Added a subtle inner shadow at the top of the glass to give depth below the lid
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.black.opacity(0.6), lineWidth: 8)
                            .blur(radius: 4)
                            .offset(y: 4)
                            .mask(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 10) // Bottom shadow
                
                // Reflection highlight
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 350, height: 230)
                    .mask(
                        HStack {
                            Rectangle().frame(width: 25)
                            Spacer()
                        }
                        .padding(.leading, 15)
                    )
                
                // Coins/Drops
                SpriteView(scene: jarScene, options: [.allowsTransparency])
                    .frame(width: 330, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCardView: View {
    var title: String
    var value: String
    var icon: String
    var iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                Spacer()
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}
