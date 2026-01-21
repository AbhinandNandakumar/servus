
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import torch
from sentence_transformers import SentenceTransformer, util
import os
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore


# -------------------------------
# Load dataset
# -------------------------------
data = pd.read_csv("service_intents.csv")
data['text'] = data['text'].str.lower()  # lowercase preprocessing

# -------------------------------
# Load Sentence Transformer
# -------------------------------
model_name = "all-mpnet-base-v2"  # more accurate than MiniLM
model = SentenceTransformer(model_name)

# Compute embeddings for all dataset texts
print("⚡ Generating embeddings for dataset...")
data['embeddings'] = list(model.encode(data['text'], convert_to_tensor=True))
print("✅ Embeddings ready!")



genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
gemini_model = genai.GenerativeModel("models/gemini-2.5-flash")

models = genai.list_models()
for m in models:
    print(m)

# -------------------------------
# Initialize Firebase Admin SDK
# -------------------------------
# Check if Firebase is already initialized
if not firebase_admin._apps:
    # Use service account credentials if available, otherwise use default
    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT", "serviceAccountKey.json")
    if os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized with service account")
    else:
        # Initialize without credentials (will use default if available)
        firebase_admin.initialize_app()
        print("⚠️ Firebase initialized without service account - Firestore may not work")

db = firestore.client()
print("✅ Firestore client ready!")

# -------------------------------
# FastAPI app
# -------------------------------
app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Input model
class ProblemInput(BaseModel):
    problem: str

# Fallback workers data (used if Firestore is empty or unavailable)
workers_db_fallback = {
    "plumber": [{"name": "Ramesh", "location": "Mumbai", "rating": 4.7, "hourly_rate": 45, "experience": "8 years exp."}],
    "electrician": [{"name": "Suresh", "location": "Delhi", "rating": 4.5, "hourly_rate": 50, "experience": "6 years exp."}],
    "ac_technician": [{"name": "Amit", "location": "Bangalore", "rating": 4.6, "hourly_rate": 55, "experience": "5 years exp."}],
    "carpenter": [{"name": "Vikram", "location": "Chennai", "rating": 4.8, "hourly_rate": 40, "experience": "12 years exp."}],
    "appliance_repair": [{"name": "Sunil", "location": "Pune", "rating": 4.4, "hourly_rate": 35, "experience": "4 years exp."}],
    "glazier": [{"name": "Anil", "location": "Hyderabad", "rating": 4.7, "hourly_rate": 42, "experience": "7 years exp."}],
    "cleaning": [{"name": "Meena", "location": "Kolkata", "rating": 4.5, "hourly_rate": 25, "experience": "3 years exp."}],
    "computer_repair": [{"name": "Rohit", "location": "Bangalore", "rating": 4.6, "hourly_rate": 60, "experience": "5 years exp."}],
    "general_contractor": [{"name": "Deepak", "location": "Delhi", "rating": 4.6, "hourly_rate": 55, "experience": "10 years exp."}],
    "mobile_repair": [{"name": "Aakash", "location": "Mumbai", "rating": 4.5, "hourly_rate": 30, "experience": "4 years exp."}],
    "pest_control": [{"name": "Kiran", "location": "Chennai", "rating": 4.7, "hourly_rate": 45, "experience": "6 years exp."}],
    "home_automation": [{"name": "Ananya", "location": "Bangalore", "rating": 4.6, "hourly_rate": 70, "experience": "5 years exp."}],
    "solar_technician": [{"name": "Rajat", "location": "Pune", "rating": 4.8, "hourly_rate": 65, "experience": "7 years exp."}],
    "specialized_services": [{"name": "Sneha", "location": "Delhi", "rating": 4.6, "hourly_rate": 50, "experience": "8 years exp."}],
    "gas_technician": [{"name": "Manish", "location": "Chennai", "rating": 4.5, "hourly_rate": 48, "experience": "6 years exp."}],
    "automobile_mechanic": [{"name": "Ajay", "location": "Mumbai", "rating": 4.6, "hourly_rate": 55, "experience": "9 years exp."}],
    "locksmith": [{"name": "Vikas", "location": "Delhi", "rating": 4.5, "hourly_rate": 35, "experience": "5 years exp."}],
    "welder": [{"name": "Ravi", "location": "Bangalore", "rating": 4.7, "hourly_rate": 50, "experience": "8 years exp."}]
}

# Function to get workers from Firestore
def get_workers_from_firestore(category: str) -> list:
    """Fetch workers from Firestore by category, fallback to hardcoded data if empty"""
    try:
        workers_ref = db.collection('workers').where('category', '==', category)
        docs = workers_ref.stream()

        workers = []
        for doc in docs:
            worker_data = doc.to_dict()
            worker_data['id'] = doc.id
            workers.append(worker_data)

        # If Firestore has workers, return them
        if workers:
            print(f"✅ Found {len(workers)} workers in Firestore for category: {category}")
            return workers

        # Fallback to hardcoded data
        print(f"⚠️ No workers in Firestore for {category}, using fallback data")
        return workers_db_fallback.get(category, [])

    except Exception as e:
        print(f"❌ Error fetching from Firestore: {e}")
        return workers_db_fallback.get(category, [])



def generate_quick_fix(problem: str, category: str) -> str:
    # Hardcoded quick fix to avoid Gemini API rate limits
    # Uncomment the code below to enable Gemini API calls
    return "Turn off the main supply and keep the area dry until the professional arrives."

    # --- GEMINI API CODE (commented out to save API calls) ---
    # print("🧠 Gemini prompt called:", problem, category)
    #
    # prompt = f"""
    # You are a home service expert.
    #
    # User problem:
    # {problem}
    #
    # Detected service category:
    # {category}
    #
    # Give 2–3 short, safe, temporary quick-fix suggestions.
    #
    # Rules:
    # - Do NOT suggest professional repairs
    # - Do NOT mention complex tools
    # - Keep advice safe and simple
    # - Use bullet points
    # """
    #
    # try:
    #     response = gemini_model.generate_content(prompt)
    #     return response.text.strip()
    # except Exception as e:
    #     print("❌ Gemini Error:", e)
    #     return "Please take basic safety precautions until a professional arrives."


# -------------------------------
# API Endpoint
# -------------------------------
@app.post("/analyze")
async def analyze(problem_input: ProblemInput):
    query = problem_input.problem.lower().strip()
    
    # Embed query
    query_emb = model.encode(query, convert_to_tensor=True)
    
    # Compute cosine similarity
    cos_scores = util.cos_sim(query_emb, torch.stack(data['embeddings'].to_list()))[0]
    
    # Get top-k results
    top_k = 5
    threshold = 0.55
    top_results = torch.topk(cos_scores, k=top_k)
    
    best_category = None
    for score, idx in zip(top_results.values, top_results.indices):
        idx = idx.item()  # convert tensor to integer
        if score >= threshold:
            best_category = data.iloc[idx]['category']
            break
    
    if best_category is None:
        best_category = "general_contractor"
    
    available_workers = get_workers_from_firestore(best_category)
    quick_fix = generate_quick_fix(problem_input.problem, best_category)


    return {
        "detected_category": best_category,
        "available_workers": available_workers,
        "quick_fix": quick_fix
    }

# -------------------------------
# Seed workers endpoint (run once to populate Firestore)
# -------------------------------
@app.post("/seed-workers")
async def seed_workers():
    """Seed initial workers data to Firestore"""
    try:
        # Check if workers collection already has data
        existing = db.collection('workers').limit(1).get()
        if len(existing) > 0:
            return {"message": "Workers collection already has data", "seeded": False}

        # Seed all workers from fallback data
        count = 0
        for category, workers in workers_db_fallback.items():
            for worker in workers:
                worker_data = {**worker, "category": category, "verified": True}
                db.collection('workers').add(worker_data)
                count += 1

        return {"message": f"Successfully seeded {count} workers to Firestore", "seeded": True}
    except Exception as e:
        return {"error": str(e), "seeded": False}

# -------------------------------
# Root
# -------------------------------
@app.get("/")
def root():
    return {"message": "AI Service Marketplace API is running."}
print("🚀 FastAPI app ready! Run using: uvicorn app:app --reload")