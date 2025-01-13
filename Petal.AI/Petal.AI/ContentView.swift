import SwiftUI
import UserNotifications

// MARK: - Notification Functions
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
        if let error = error {
            print("Error requesting notifications permission: \(error)")
        }
    }
}

func scheduleDailyReminder() {
    let content = UNMutableNotificationContent()
    content.title = "Daily Reminder"
    content.body = "Don't forget to continue your streak!"
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.hour = 9 // Schedule for 9 AM daily

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling daily reminder: \(error)")
        }
    }
}

func cancelDailyReminder() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
}

// MARK: - ContentView
struct ContentView: View {
    @State private var fontSize: CGFloat = 16
    @State private var selectedTab: String = "Home" // Track the selected tab
    @State private var streakCount: Int = 0 // Track the streak count
    @State private var weeklyStreak: [Bool] = [
        true, true, false, true, true, true, false, // This week
        true, false, true, true, true, false, true  // Last week
    ]
    @State private var recentMessages: [Message] = loadRecentMessages() // Recent chat messages
    @State private var latestUserMessage: String = ""
    @State private var latestAIResponse: String = ""
    @State private var isReminderEnabled: Bool = false // Toggle for reminders
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
// MARK: - Home
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Streak Card
                        VStack(alignment: .leading) {
                            Text("Weekly Streak")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            VStack(spacing: 16) {
                                // First week
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("This Week")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(0..<7, id: \.self) { day in
                                            VStack {
                                                Circle()
                                                    .fill(weeklyStreak[day] ? Theme.accentColor : Color.white.opacity(0.3))
                                                    .frame(width: 35, height: 35)
                                                Text(getDayName(for: day))
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                
                                // Second week
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Week")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(7..<14, id: \.self) { day in
                                            VStack {
                                                Circle()
                                                    .fill(weeklyStreak[day - 7] ? Theme.accentColor : Color.white.opacity(0.3))
                                                    .frame(width: 35, height: 35)
                                                Text(getDayName(for: day - 7))
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                
                                Text("\(streakCount) days streak")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Theme.streakCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.vertical, Theme.cardSpacing)
                        
                        // Quick Chat Preview
                        VStack(alignment: .leading) {
                            Text("Recent Chat")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            if !latestUserMessage.isEmpty {
                                Text(latestUserMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 2)
                                
                                Text(latestAIResponse)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.vertical, 2)
                            } else {
                                ForEach(recentMessages) { message in
                                    Text(message.text)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 2)
                                }
                            }
                            
                            Button(action: {
                                selectedTab = "Chat"
                            }) {
                                Text("Continue Chat")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.accentColor)
                                    .cornerRadius(Theme.cornerRadius)
                            }
                        }
                        .padding()
                        .background(Theme.chatCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.vertical, Theme.cardSpacing)
                    }
                    .padding(.bottom, 100)
                }
                
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 55)
                        .fill(Theme.overlayBackground)
                        .frame(height: 120)
                        .padding(.bottom, -88)
                        .ignoresSafeArea()
                }
            }
            .background(Theme.primaryPink)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag("Home")
            .onAppear {
                recentMessages = loadRecentMessages()
            }
            .onDisappear {
                saveRecentMessages(recentMessages)
            }
            
// MARK: - Chat
            ZStack {
                Theme.primaryPink
                    .ignoresSafeArea()
                
                VStack {
                    ScrollView{
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(recentMessages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding()
                                            .background(Color.blue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                                    } else {
                                        Text(message.text)
                                            .padding()
                                            .background(Color.gray.opacity(0.3))
                                            .foregroundColor(.black)
                                            .cornerRadius(12)
                                            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    HStack {
                        TextField("Type your message...", text: $latestUserMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 44)
                        
                        Button(action: {}) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(Theme.accentColor)
                        }
                        .disabled(latestUserMessage.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 55)
                        .fill(Theme.overlayBackground)
                        .frame(height: 120)
                        .padding(.bottom, -88)
                        .ignoresSafeArea()
                }
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag("Chat")
            
// MARK: - Settings
            ZStack {
                Theme.primaryPink
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 55)
                        .fill(Theme.overlayBackground)
                        .frame(height: 120)
                        .padding(.bottom, -88)
                        .ignoresSafeArea()
                }
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Reminders Section
                        VStack(alignment: .leading) {
                            Text("Reminders")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            Toggle("Enable Daily Reminders", isOn: $isReminderEnabled)
                                .onChange(of: isReminderEnabled) { oldValue, newValue in
                                    if newValue {
                                        requestNotificationPermission()
                                        scheduleDailyReminder()
                                    } else {
                                        cancelDailyReminder()
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Theme.accentColor))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(Theme.cornerRadius)
                        }
                        .padding()
                        .background(Theme.streakCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Report an Issue
                        VStack(alignment: .leading) {
                            Text("Report an Issue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            Button(action: {
                                // Report an issue action
                            }) {
                                Text("Submit a Report")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.accentColor)
                                    .cornerRadius(Theme.cornerRadius)
                            }
                        }
                        .padding()
                        .background(Theme.streakCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Send Feedback
                        VStack(alignment: .leading) {
                            Text("Send Feedback")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            Button(action: {
                                // Send feedback action
                            }) {
                                Text("Share Your Thoughts")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.accentColor)
                                    .cornerRadius(Theme.cornerRadius)
                            }
                        }
                        .padding()
                        .background(Theme.streakCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // About Section
                        VStack(alignment: .leading) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Developed by [Your Name or Team]")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(Theme.streakCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
                    .accentColor(Theme.accentColor)
            }
            .tag("Settings")
            
        }
        .onAppear {
            UITabBar.appearance().backgroundColor = UIColor.clear
        }
        .statusBar(hidden: true)
    }
    
    private func getDayName(for index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[index]
    }
}

// MARK: - Messages
func loadRecentMessages() -> [Message] {
    if let data = UserDefaults.standard.data(forKey: "savedRecentMessages"),
       let messages = try? JSONDecoder().decode([Message].self, from: data) {
        return messages
    }
    return []
}

func saveRecentMessages(_ messages: [Message]) {
    if let encoded = try? JSONEncoder().encode(messages) {
        UserDefaults.standard.set(encoded, forKey: "savedRecentMessages")
    }
}

struct Message: Codable, Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
}
// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
