# Petal.AI
## Project Overview

This project consists of two major components:

1. **iPhone App**: Built using SwiftUI, this app serves as a personal learning coach interface that allows users to interact with an AI-powered tutor. The app provides a seamless and interactive user experience to teach and guide users through various subjects using conversational AI.

2. **GPT-2 Fine-Tuning**: The backend is powered by a fine-tuned version of GPT-2, a state-of-the-art language model that has been customized specifically to function as a personal tutor. This model has been trained with a custom dataset that allows it to respond to users' questions, provide explanations, and engage in an intelligent conversation to aid in learning new skills from the Universal Toolbox.

The app acts as a bridge between the user and the fine-tuned model, enabling an easy-to-use and intuitive interaction via natural language.

## Key Features

- **Interactive Chat Interface**: The app includes a modern and user-friendly chat interface where users can send messages to the AI tutor and receive thoughtful responses.
- **Weekly Streak Tracker**: The app keeps track of a user's learning progress through a weekly streak counter, motivating users to stay consistent.
- **Recent Messages Preview**: Users can view their most recent interactions with the AI tutor.
- **Reminders & Settings**: The app provides an option to set daily reminders to encourage consistent learning, along with various user-configurable settings.

## Technologies Used

### iOS App:
- **Swift**: The primary programming language used to develop the app, providing a native experience on iPhone devices.
- **SwiftUI**: Apple's declarative framework used to build the user interface with clean and scalable code.
- **GPT-2**: A pre-trained language model that has been fine-tuned for the purpose of serving as a personal learning assistant.
- **Core Data / UserDefaults**: For storing the user's progress, recent messages, and app state.
- **Firebase**: Optionally, can be used for storing user data or handling chat logs for a more personalized experience.

### GPT-2 Fine-Tuning:
- **Hugging Face Transformers**: A library used to fine-tune the GPT-2 model with a custom dataset of learning materials, ensuring the AI is capable of responding accurately to user queries.
- **Python**: The scripting language used to preprocess data and fine-tune GPT-2.
- **PyTorch**: Framework used for fine-tuning the GPT-2 model.

---

## TODOs:

1. **Integrate the Model into the App**:
   - Set up an API or local inference engine to integrate the fine-tuned GPT-2 model into the app.
   - Create a backend service or use a local model for generating responses based on user queries.

2. **Make the Streak and Recent Chats Functional**:
   - Implement the streak tracker to correctly update based on user interactions.
   - Make the recent chat feature work by saving the user's chat history and displaying it in the interface.

3. **Work on Report/Feedback Functions**:
   - Implement functionality for users to report issues within the app, and send feedback to improve the AI tutor experience.
   - Allow users to submit reports and feedback, which will be handled appropriately (e.g., via email or API).

---

## App Usage

1. **Home Screen**: The Home tab provides an overview of your progress, with a weekly streak tracker and a recent chat preview.
2. **Chat Screen**: The Chat tab is where you can interact with your personal AI tutor. You can ask questions, get explanations, and receive personalized learning support.
3. **Settings Screen**: The Settings tab allows you to configure reminders, report issues, and send feedback.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Hugging Face** for the Transformers library, which made fine-tuning GPT-2 easy.
- **Apple** for providing Swift and SwiftUI for building beautiful and performant iOS apps.
- **OpenAI** for GPT-2, the powerful language model that powers this personal learning coach.

For any questions or issues, feel free to open an issue or reach out to us directly via the repository!
