import torch
from sqlalchemy import create_engine
import pandas as pd
from transformers import AutoTokenizer, AutoModelForCausalLM, Trainer, TrainingArguments
from datasets import Dataset
import chardet
import random

# Step 1: Load and Clean CSV
def clean_and_load_csv(file_path):
    try:
        with open(file_path, "rb") as f:
            result = chardet.detect(f.read())
        encoding = result["encoding"]
        print(f"Detected encoding: {encoding}")
    except Exception as e:
        print(f"Error detecting encoding: {e}")
        return None, None

    try:
        print(f"Loading CSV file: {file_path}")
        df = pd.read_csv(file_path, encoding=encoding, on_bad_lines="skip")
        print(f"CSV loaded with {len(df)} rows after cleaning.")

        # Ensure no NaN values and focus on relevant columns
        df = df.astype(object).where(pd.notnull(df), None)
        df = df[["Prompt", "Response"]]  # Focus on fine-tuning data

        cleaned_file = "cleaned_data.csv"
        df.to_csv(cleaned_file, index=False, encoding="utf-8")
        print(f"Cleaned CSV saved as '{cleaned_file}'.")

        return df, cleaned_file
    except Exception as e:
        print(f"Error loading and cleaning CSV: {e}")
        return None, None

# Step 2: Load CSV into a Database
def load_csv_to_database(df, database_url, table_name):
    if df is None:
        print("No DataFrame to load into the database.")
        return None

    try:
        print(f"Connecting to database: {database_url}")
        engine = create_engine(database_url)
        print("Database connection successful!")
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

    try:
        print(f"Saving DataFrame to table: {table_name}")
        df.to_sql(table_name, engine, if_exists="replace", index=False)
        print(f"Data saved to table '{table_name}' successfully!")
        return engine
    except Exception as e:
        print(f"Error saving data to database: {e}")
        return None

# Step 3: Query the Database
def query_database(engine, table_name):
    query = f"SELECT * FROM {table_name}"
    try:
        print(f"Querying table: {table_name}")
        with engine.connect() as connection:
            df = pd.read_sql(query, connection)
        print(f"Retrieved {len(df)} rows from the database.")
        return df
    except Exception as e:
        print(f"Error querying database: {e}")
        return None

# Step 4: Fine-tune the Model
def fine_tune_model(df, model_dir, output_dir):
    try:
        model = AutoModelForCausalLM.from_pretrained(model_dir)
        tokenizer = AutoTokenizer.from_pretrained(model_dir)

        # Set pad token to eos token
        tokenizer.pad_token = tokenizer.eos_token  

        dataset = Dataset.from_pandas(df)
        def preprocess(batch):
            templates = [
                f"User: {batch['Prompt']}\nAssistant: {batch['Response']}",
                f"The user asked: {batch['Prompt']}\nHere's the response: {batch['Response']}",
                 f"Question: {batch['Prompt']}\nAnswer: {batch['Response']}"
                ]
            template = random.choice(templates)  # Randomize prompt structure
            encoded = tokenizer(
                template,
                truncation=True,
                max_length=512,
                padding="max_length",
                return_tensors="pt"
                )
            return {
                "input_ids": encoded["input_ids"].squeeze(),
                "attention_mask": encoded["attention_mask"].squeeze(),
                "labels": encoded["input_ids"].squeeze()
            }

        tokenized_dataset = dataset.map(preprocess, remove_columns=dataset.column_names)

        training_args = TrainingArguments(
            output_dir=output_dir,
            per_device_train_batch_size=2,
            gradient_accumulation_steps=8,
            learning_rate=2e-4,
            num_train_epochs=19,
            save_strategy="epoch",
            save_total_limit=2,
            logging_dir="./logs",
            optim="adamw_torch",
            warmup_ratio=0.03,
        )

        trainer = Trainer(
            model=model,
            args=training_args,
            train_dataset=tokenized_dataset,
            tokenizer=tokenizer,
        )

        trainer.train()
        model.save_pretrained(output_dir)
        tokenizer.save_pretrained(output_dir)
        print(f"Model fine-tuned and saved at {output_dir}")

    except Exception as e:
        print(f"Error during fine-tuning: {e}")

# Step 5: Test the Fine-tuned Model
def test_model(model_dir, prompt):
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_dir)
        model = AutoModelForCausalLM.from_pretrained(model_dir)

        device = "mps"
        model.to(device)

        inputs = tokenizer(prompt, return_tensors="pt", padding=True).to(device)

        outputs = model.generate(
            inputs["input_ids"],
            attention_mask=inputs["attention_mask"],
            max_length=200,  # Allow longer responses
            num_return_sequences=1,
            temperature=1.3,  # Encourage diversity in responses
            top_k=100,         # Restrict to top-k likely words
            top_p=0.9,       # Nucleus sampling for better creativity
            do_sample=True    # Enables sampling for varied responses
        )
        
        # Decode and display the generated response
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        print(f"Generated response: {generated_text}")
    except Exception as e:
        print(f"Error during testing: {e}")
        
        # Decode output and remove special tokens
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        print(f"Generated response: {generated_text}")
    except Exception as e:
        print(f"Error during testing: {e}")

# Main function
def main():
    try:
        csv_file = "/Users/nick/Developer/Personal_Project/Python/CSV/skills.csv"
        database_url = "sqlite:///my_database.db"
        table_name = "training_data"
        model_dir = "/Users/nick/Developer/Personal_Project/Python/Models/gpt2"
        output_dir = "/Users/nick/Developer/Personal_Project/Python/Models/gpt2-trained"
        test_prompt = "How can I improve my public speaking skills?"

        df, cleaned_file = clean_and_load_csv(csv_file)
        if df is None:
            print("Error cleaning and loading CSV.")
            return

        engine = load_csv_to_database(df, database_url, table_name)
        if engine is None:
            print("Error loading DataFrame into database.")
            return

        df = query_database(engine, table_name)
        if df is None:
            print("Error querying database.")
            return

        fine_tune_model(df, model_dir, output_dir)
        test_model(output_dir, test_prompt)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()