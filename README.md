# 🏦 IDBI Saarthi - Your AI Wealth Companion

**Team LINGO** | **Lead:** THAMEEM MUL ANSARI S 
**Domain:** Digital Wealth Management 

IDBI Saarthi is an AI-powered digital wealth companion designed to democratize financial advisory. By combining a 360° financial view with a human-backed trust model, Saarthi delivers goal-based guidance and enterprise-grade wealth advisory for all. 

---

## 🚀 Quick Links
* **Prototype Video:** [IDBI_Saarthi_POC_Video_Link](https://drive.google.com/drive/folders/1oVmIbf0paiDCUS1mRqng3tZR-jL2Zx3v) 
* **GitHub Repository:** [Thameem-Mul-Ansari/IDBI-Saarthi](https://github.com/Thameem-Mul-Ansari/IDBI-Saarthi) 

---

## 💡 The Problem & Opportunity
Traditional wealth management is often inaccessible to everyday investors. IDBI Saarthi bridges this gap by capturing Gen Z investors and providing an inclusive-by-architecture solution. We leverage behavioral personalization and an AI + Human advisory model to ensure personalization that is actually personal.

---

## ✨ Key Features

### 🎙️ For the Customer
* **Avatar-Led Advisory:** Engaging, voice-driven interactive AI avatar.
* **360° Financial View:** Complete visibility into transactions, holdings, goals, and preferences.
* **Goal-Based Guidance:** Proactive financial nudges and grounded AI recommendations.
* **What-If Simulator:** Plan, simulate, and optimize financial goals in real-time.

### 💼 For the Relationship Manager (RM)
* **RM Smart Lead Briefing:** Auto-generated lead summaries and escalation logic for high-value or complex queries.
* **Self-Updating Knowledge Base:** Admin dashboard to manage and control AI knowledge[cite: 3].
* **Personalized Live Market Pulse:** Real-time market context for better client conversations[cite: 3].

---

## 🛠️ Architecture & Tech Stack

Our platform is built on an enterprise-grade, compliance-native design utilizing bank-grade security (End-to-End Encryption, RBI/SEBI/ISO 27001/DPDP Act Compliant)[cite: 3].

**1. Channel Layer**
* Frontend: **Flutter** (Mobile App with In-App AI Avatar)[cite: 3]
* Dashboard: **RM Web Dashboard**[cite: 3]

**2. Orchestration & Backend**
* Framework: **FastAPI**[cite: 3]
* AI Orchestration: **LangChain**[cite: 3]

**3. AI & Knowledge Layer**
* Reasoning Engine: **Azure OpenAI (GPT-4o & GPT-4o mini** for tiered routing)[cite: 3]
* Voice/Vision: **Azure AI Speech** & **Azure AI Avatar** (Text-to-Speech Avatar)[cite: 3]
* Vector Search: **Azure AI Search**[cite: 3]

**4. Data & Storage Layer**
* Databases: **Azure Cosmos DB** (NoSQL) & **Azure Blob Storage** (Document Storage)[cite: 3]
* RAG Sources: **IDBI Product Catalog, AMFI, SEBI, RBI, NewsAPI** (Live Market Feeds)[cite: 3]

---

## ⚙️ Setup & Installation

### Prerequisites
* Flutter SDK (Latest stable version)
* Android Studio / Xcode
* Active Azure Subscription (OpenAI & Speech Services)

### 1. Clone the Repository
```bash
git clone https://github.com/Thameem-Mul-Ansari/IDBI-Saarthi.git
cd IDBI-Saarthi
