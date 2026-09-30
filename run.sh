#!/bin/bash
# Maritime Chartering Decision Platform - Start Script (Linux/Mac)

echo "🚢 Maritime Chartering Decision Platform"
echo "========================================"

# Check Python
PYTHON_BIN="python3"
for candidate in python3.11 python3.10 python3.9 python3; do
    if command -v "$candidate" &> /dev/null; then
        PYTHON_BIN="$candidate"
        break
    fi
done

if ! command -v "$PYTHON_BIN" &> /dev/null; then
    echo "❌ Python 3 is required. Install from https://python.org"
    exit 1
fi

# Check Node
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required. Install from https://nodejs.org"
    exit 1
fi

# Backend setup
echo ""
echo "🔧 Setting up backend..."
cd backend

if [ ! -d "venv" ]; then
    echo "Creating virtual environment with $PYTHON_BIN..."
    "$PYTHON_BIN" -m venv venv
fi

source venv/bin/activate
CMAKE_POLICY_VERSION_MINIMUM=3.5 pip install -r requirements.txt --quiet

# Generate data if not exists
if [ ! -f "data/freight_rates.csv" ]; then
    echo "📊 Generating synthetic training data..."
    python data/generate_synthetic_data.py
fi

# Start backend in background
echo "🚀 Starting backend server on port 8000..."
uvicorn main:app --reload --port 8000 &
BACKEND_PID=$!
cd ..

# Frontend setup
echo ""
echo "🔧 Setting up frontend..."
cd frontend

if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi

# Start frontend
echo "🚀 Starting frontend on port 5173..."
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "✅ Platform is starting!"
echo "🌐 Open http://localhost:5173 in your browser"
echo ""
echo "Press Ctrl+C to stop both servers"

# Cleanup on exit
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM
wait
