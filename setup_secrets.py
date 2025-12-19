import json
import subprocess
import os
import sys

def check_gh_installed():
    try:
        subprocess.run(["gh", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except FileNotFoundError:
        print("❌ Error: 'gh' (GitHub CLI) is not installed.")
        print("   Please install it: https://cli.github.com/manual/installation")
        return False

def set_secrets():
    if not check_gh_installed():
        return

    secrets_file = "secrets.json"
    if not os.path.exists(secrets_file):
        print(f"❌ Error: '{secrets_file}' not found.")
        print("   1. Copy 'secrets.template.json' to 'secrets.json'")
        print("   2. Fill in your AWS credentials")
        return

    try:
        with open(secrets_file, "r") as f:
            secrets = json.load(f)
    except json.JSONDecodeError:
        print(f"❌ Error: Failed to parse '{secrets_file}'. Check JSON syntax.")
        return

    print("🚀 Setting secrets in GitHub repository...")
    
    for key, value in secrets.items():
        if value and "YOUR_" not in value:
            print(f"   - Setting {key}...")
            try:
                # Pipe value to gh secret set to avoid logging it
                proc = subprocess.Popen(
                    ["gh", "secret", "set", key], 
                    stdin=subprocess.PIPE, 
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.PIPE,
                    text=True
                )
                stdout, stderr = proc.communicate(input=value)
                
                if proc.returncode != 0:
                    print(f"     ⚠️ {stderr.strip()}")
                else:
                    print("     ✅ OK")
            except Exception as e:
                print(f"     ❌ Failed: {e}")
        else:
            print(f"   - Skipping {key} (Empty or Default Value)")

    print("\n✅ Done! Secrets updated.")

if __name__ == "__main__":
    set_secrets()
