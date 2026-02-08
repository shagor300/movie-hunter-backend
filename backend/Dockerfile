# ১. প্লে-রাইটের অফিসিয়াল ইমেজ ব্যবহার (সব ডিপেন্ডেন্সি এতে আছে)
FROM mcr.microsoft.com/playwright/python:v1.40.0-jammy

WORKDIR /app

# ২. পাইথন ডিপেন্ডেন্সি ইনস্টল
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ৩. শুধু ব্রাউজার ইনস্টল করা (অপ্রয়োজনীয় প্যাকেজ লিস্ট বাদ দেওয়া হয়েছে)
RUN playwright install chromium

# ৪. অ্যাপ কোড কপি করা
COPY . .

# ৫. পোর্ট এক্সপোজ করা
EXPOSE 8000

# ৬. অ্যাপ্লিকেশন রান করা
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

