import pandas as pd

# Function to load and process CSV into prompt/response pairs
def process_csv_for_finetuning(file_path, delimiter=';'):
    try:
        # Load the CSV with the specified delimiter
        df = pd.read_csv(file_path, delimiter=delimiter, on_bad_lines='skip')
        
        # Check columns in the CSV
        print("CSV Columns: ", df.columns)

        # Check if required columns exist
        required_columns = ['mainaccord1', 'mainaccord2', 'mainaccord3', 'Perfume', 'Brand']
        if not all(col in df.columns for col in required_columns):
            raise ValueError(f"CSV is missing required columns: {required_columns}")
        
        # Creating the prompt and response columns
        prompts = []
        responses = []

        for _, row in df.iterrows():
            # Build the prompt by concatenating relevant columns
            prompt = f"What is a fragrance with top notes of {row['mainaccord1']}, 
            middle notes of {row['mainaccord2']}, and base notes of {row['mainaccord3']}?"
            
            # Build the response based on relevant columns
            response = f"This fragrance is {row['Perfume']} from {row['Brand']}"
            
            prompts.append(prompt)
            responses.append(response)
        
        # Create a DataFrame with the new prompt and response columns
        finetune_df = pd.DataFrame({
            'prompt': prompts,
            'response': responses
        })

        print(f"Processed {len(finetune_df)} prompt/response pairs.")
        return finetune_df
    except Exception as e:
        print(f"Error processing CSV: {e}")
        return None

# Example usage
file_path = "/Users/nick/Downloads/Box Data from Nikolas.csv"  # Replace with your actual CSV file path
processed_df = process_csv_for_finetuning(file_path)

if processed_df is not None:
    # Optionally, save the processed CSV to file
    processed_df.to_csv("processed_data_for_finetuning.csv", index=False)
    print("Processed data saved as 'processed_data_for_finetuning.csv'.")