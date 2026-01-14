import pickle

# Load model
with open("model.pkl", "rb") as f:
    model = pickle.load(f)

# Load vectorizer
with open("vectorizer.pkl", "rb") as f:
    vectorizer = pickle.load(f)

# Test input
test_problem = "Water is leaking from my kitchen pipe"

# Transform input
X = vectorizer.transform([test_problem])

# Predict
prediction = model.predict(X)

print("Prediction:", prediction[0])
