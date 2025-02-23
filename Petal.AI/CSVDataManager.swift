import Foundation

struct SkillData: Codable {
    let prompt: String
    let response: String
    let skill: String
    let followUpQuestion: String
    let tips: [String]
    
    enum CodingKeys: String, CodingKey {
        case prompt = "Prompt"
        case response = "Response"
        case skill = "Skill"
        case followUpQuestion = "Follow-Up Question"
        case tips = "Tips"
    }
}

struct ResponseConfig {
    var maxLength: Int
    var includeFollowUp: Bool
    var includeTips: Bool
    var systemPrompt: String
    
    static let `default` = ResponseConfig(
        maxLength: 500,
        includeFollowUp: true,
        includeTips: true,
        systemPrompt: (try? String(contentsOfFile: Bundle.main.path(forResource: "system_prompt", ofType: "txt") ?? "", encoding: .utf8)) ?? ""
    )
}

class CSVDataManager {
    static let shared = CSVDataManager()
    private var skillsData: [SkillData] = []
    
    private init() {
        loadSkillsData()
    }
    
    private func loadSkillsData() {
        guard let path = Bundle.main.path(forResource: "skills", ofType: "csv") else {
            print("Could not find skills.csv in bundle")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            // Skip header row
            for row in rows.dropFirst() where !row.isEmpty {
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 7 else { continue }
                
                let skillData = SkillData(
                    prompt: columns[0].trimmingCharacters(in: .init(charactersIn: "\"")),
                    response: columns[1].trimmingCharacters(in: .init(charactersIn: "\"")),
                    skill: columns[2].trimmingCharacters(in: .init(charactersIn: "\"")),
                    followUpQuestion: columns[3].trimmingCharacters(in: .init(charactersIn: "\"")),
                    tips: [
                        columns[4].trimmingCharacters(in: .init(charactersIn: "\"")),
                        columns[5].trimmingCharacters(in: .init(charactersIn: "\"")),
                        columns[6].trimmingCharacters(in: .init(charactersIn: "\""))
                    ]
                )
                skillsData.append(skillData)
            }
        } catch {
            print("Error reading CSV file: \(error)")
        }
    }
    
    func getContextForPrompt(_ prompt: String, config: ResponseConfig = .default) -> String {
        // Find relevant skills data based on the prompt
        let relevantData = skillsData.filter { data in
            prompt.lowercased().contains(data.skill.lowercased()) ||
            prompt.lowercased().contains(data.prompt.lowercased())
        }
        
        // Create context string starting with system prompt
        var context = "System: \(config.systemPrompt)\n\nBased on our skills database:\n"
        var currentLength = context.count
        
        for data in relevantData {
            let skillSection = "\nSkill: \(data.skill)\n" +
                             "Similar situation: \(data.prompt)\n" +
                             "Suggested response: \(data.response)\n"
            
            // Check if adding this section would exceed max length
            if currentLength + skillSection.count > config.maxLength {
                break
            }
            
            context += skillSection
            currentLength += skillSection.count
            
            if config.includeFollowUp {
                let followUpSection = "Follow-up: \(data.followUpQuestion)\n"
                if currentLength + followUpSection.count <= config.maxLength {
                    context += followUpSection
                    currentLength += followUpSection.count
                }
            }
            
            if config.includeTips {
                context += "Tips:\n"
                currentLength += 6
                
                for tip in data.tips {
                    let tipSection = "- \(tip)\n"
                    if currentLength + tipSection.count <= config.maxLength {
                        context += tipSection
                        currentLength += tipSection.count
                    } else {
                        break
                    }
                }
            }
        }
        
        return context
    }
}