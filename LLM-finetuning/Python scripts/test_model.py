from transformers import AutoModelForCausalLM, AutoTokenizer

model_dir = "../Models/gpt2-trained"
model = AutoModelForCausalLM.from_pretrained(model_dir)
tokenizer = AutoTokenizer.from_pretrained(model_dir)

# Test the model with a prompt
test_prompt = "How can I handle criticism better?"
inputs = tokenizer(test_prompt, return_tensors="pt")

# Generate output without num_return_sequences
outputs = model.generate(**inputs, max_new_tokens=1250)
response = tokenizer.decode(outputs[0], skip_special_tokens=True)

print(response)
