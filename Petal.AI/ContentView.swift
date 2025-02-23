import GoogleGenerativeAI
import SwiftUI
import UserNotifications

// MARK: - Notification Functions
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
        granted, error in
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
    dateComponents.hour = 9  // Schedule for 9 AM daily

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
        identifier: "dailyReminder", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling daily reminder: \(error)")
        }
    }
}

func cancelDailyReminder() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        "dailyReminder"
    ])
}

// MARK: - ContentView
struct ContentView: View {
    @State private var fontSize: CGFloat = 16
    @State private var selectedTab: String = "Home"  // Track the selected tab
    @State private var streakCount: Int = 0  // Track the streak count
    @State private var weeklyStreak: [Bool] =
        UserDefaults.standard.array(forKey: "weeklyStreak") as? [Bool]
        ?? Array(repeating: false, count: 7)
    @State private var lastInteractionDate: Date? =
        UserDefaults.standard.object(forKey: "lastInteractionDate") as? Date
    @State private var recentMessages: [Message] = []  // Recent chat messages
    @State private var isReminderEnabled: Bool = false  // Toggle for reminders
    @State private var messageText: String = ""  // Message input text
    @State private var isLoading: Bool = false
    private let model = GenerativeModel(name: "gemini-2.0-flash", apiKey: APIKey.default)
    private let maxMessageCount = 50  // Maximum number of messages to keep

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Home
            ZStack {
                VStack {
                    VStack(spacing: 8) {
                        // Streak Card
                        StreakCardView()
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

                            if recentMessages.isEmpty {
                                Text("Start a conversation in the Chat tab!")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 2)
                            } else {
                                ScrollView {
                                    VStack(spacing: 8) {
                                        ForEach(recentMessages.prefix(3)) { message in
                                            MessageBubble(message: message)
                                        }
                                    }
                                }
                                .frame(height: 120)
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

                            Button(action: {
                                // Clear all messages
                                recentMessages.removeAll()
                                UserDefaults.standard.removeObject(forKey: "savedRecentMessages")
                                // Navigate to chat tab
                                selectedTab = "Chat"
                            }) {
                                Text("New Chat")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(Theme.cornerRadius)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Theme.chatCardBackground)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.vertical, Theme.cardSpacing)
                    }
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

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(recentMessages) { message in
                                MessageBubble(message: message)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    if isLoading {
                        LoadingSpinner()
                            .padding()
                    }
                    Spacer()

                    // Message Input Bar
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.white)

                        Button(action: {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            {
                                let userMessage = Message(
                                    id: UUID(), text: messageText, isUser: true)
                                // Add new message and trim if needed
                                recentMessages.append(userMessage)
                                if recentMessages.count > maxMessageCount {
                                    recentMessages.removeFirst(
                                        recentMessages.count - maxMessageCount)
                                }

                                // Update streak for today
                                lastInteractionDate = Date()
                                UserDefaults.standard.set(
                                    lastInteractionDate, forKey: "lastInteractionDate")
                                updateStreak()
                                let userInput = messageText
                                messageText = ""
                                isLoading = true

                                Task {
                                    do {
                                        let chat = model.startChat()
                                        // Get context from skills database
                                        let context = CSVDataManager.shared.getContextForPrompt(
                                            userInput)
                                        // Add context to the user's message
                                        let promptWithContext =
                                            context + "\n\nUser message: " + userInput
                                        let response = try await chat.sendMessage(promptWithContext)
                                        if let text = response.text {
                                            DispatchQueue.main.async {
                                                let aiMessage = Message(
                                                    id: UUID(), text: text, isUser: false)
                                                recentMessages.append(aiMessage)
                                                saveRecentMessages(recentMessages)
                                                isLoading = false
                                            }
                                        }
                                    } catch {
                                        print("Error generating response: \(error)")
                                        DispatchQueue.main.async {
                                            let errorMessage = Message(
                                                id: UUID(),
                                                text:
                                                    "Sorry, I encountered an error. Please try again.",
                                                isUser: false)
                                            recentMessages.append(errorMessage)
                                            saveRecentMessages(recentMessages)
                                            isLoading = false
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.accentColor)
                        }
                    }
                    .padding()
                    .background(Theme.overlayBackground)
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
                VStack {
                    VStack(spacing: 10) {

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
                                let reportSheet = ReportIssueSheet()
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                                    window.rootViewController?.present(UIHostingController(rootView: reportSheet), animated: true)
                                }
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

                            Text("Developed by Nick Trimandylis")
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
        .onDisappear {
            // Clear messages when app is closed
            recentMessages.removeAll()
            UserDefaults.standard.removeObject(forKey: "savedRecentMessages")
        }
        .statusBar(hidden: true)
    }

    // MARK: Report Issue Sheet
    struct FeedbackSheet: View {
        @State private var title = ""
        @State private var description = ""

        var body: some View {
            VStack(alignment: .leading) {
                Text("Share your feedback about")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Petal.AI")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.accentColor)

                Text("We'd love to hear your thoughts and suggestions:")
                    .font(.callout)
                    .foregroundColor(.white)

                TextField("Enter feedback title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 20)
                TextField("Share your feedback in detail:", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .background(Theme.backgroundColor)
            .cornerRadius(Theme.cornerRadius)

            Button(action: {
                // Submit feedback
                self.submitFeedback()
            }) {
                Text("Submit Feedback")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.accentColor)
                    .cornerRadius(Theme.cornerRadius)
            }
        }

        // MARK: Submit feedback
        private func submitFeedback() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            FeedbackManager.shared.sendFeedback(title: title, description: description, from: rootViewController)
        }
    }

    private func getDayName(for index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[index]
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()

        // Get start of current week (Sunday)
        let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        // Get dates for current week
        let weekDates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart)
        }

        // Update this week's streak based on today's interaction
        for (index, date) in weekDates.enumerated() {
            if let lastInteraction = lastInteractionDate {
                weeklyStreak[index] = calendar.isDate(date, inSameDayAs: lastInteraction)
            } else {
                weeklyStreak[index] = false
            }
        }

        // Save weekly streak to UserDefaults
        UserDefaults.standard.set(weeklyStreak, forKey: "weeklyStreak")

        // Calculate streak count based on consecutive days of interaction
        var count = 0
        if let lastInteraction = lastInteractionDate {
            // Check if there's an interaction today
            if calendar.isDateInToday(lastInteraction) {
                count = 1
                var currentDate = calendar.startOfDay(for: today)

                // Check previous days
                while true {
                    guard
                        let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate)
                    else { break }

                    // Check if there was an interaction on the previous day
                    let previousInteraction =
                        UserDefaults.standard.object(forKey: "lastInteractionDate_\(previousDate)")
                        as? Date
                    if previousInteraction != nil {
                        count += 1
                        currentDate = previousDate
                    } else {
                        break
                    }
                }
            }
        }

        streakCount = count

        // Save today's interaction date with a unique key
        if let interaction = lastInteractionDate,
            calendar.isDateInToday(interaction)
        {
            UserDefaults.standard.set(
                interaction, forKey: "lastInteractionDate_\(calendar.startOfDay(for: today))")
        }
    }
}

// MARK: - Messages
func loadRecentMessages() -> [Message] {
    if let data = UserDefaults.standard.data(forKey: "savedRecentMessages"),
        let messages = try? JSONDecoder().decode([Message].self, from: data)
    {
        // Filter out messages older than 2 days
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        return messages.filter { $0.timestamp > twoDaysAgo }
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
    var loading: Bool = false
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, loading: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.loading = loading
        self.timestamp = Date()
    }
}
// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
