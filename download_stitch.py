import requests
import json
import os

from urllib.parse import unquote

def download_html(url, filename):
    try:
        response = requests.get(url)
        response.raise_for_status()
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(response.text)
        print(f"✅ Saved {filename}")
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}")

# The URLs returned from the Stitch API
splash_url = "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sX2E3ZWU1ODkyYTMyNjRkYjlhMmE1NWFjMjNiM2Y0ZjQyEgsSBxDdyYOczw8YAZIBIwoKcHJvamVjdF9pZBIVQhM4NDU2ODIwODQ4MzgyOTgwNjQ3&filename=&opi=89354086"
onboarding_url = "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzcwMmEwYTZkOGUwMjQzNjViN2EwMTEyMzA0NDhhYTAwEgsSBxDdyYOczw8YAZIBIwoKcHJvamVjdF9pZBIVQhM4NDU2ODIwODQ4MzgyOTgwNjQ3&filename=&opi=89354086"

os.makedirs('stitch_temp', exist_ok=True)
download_html(splash_url, 'stitch_temp/splash.html')
download_html(onboarding_url, 'stitch_temp/onboarding.html')
