import os
import requests
from openai import OpenAI

# ── Config ────────────────────────────────────────
SPRING_BOOT_URL = "http://localhost:8080"  # we'll update this after wiring API GW
OPENAI_API_KEY  = os.environ.get("OPENAI_API_KEY", "")

# ── Step 1: Generate CSV via ChatGPT ─────────────
def generate_csv():
    import random
    from datetime import datetime, timedelta

    rows = ["device_id,timestamp,temperature,humidity,pressure,status,location"]
    base_time = datetime(2024, 1, 1, 0, 0, 0)
    devices   = [f"SENSOR-{i:03d}" for i in range(1, 11)]
    locations = ["building_a", "building_b", "outdoor"]

    for i in range(100):
        ts          = base_time + timedelta(hours=i)
        device      = random.choice(devices)
        temperature = round(random.uniform(15, 35) + i * 0.01, 2)
        humidity    = round(random.uniform(30, 90), 2)
        pressure    = round(random.uniform(980, 1030), 2)
        status      = "WARNING" if random.random() < 0.1 else "OK"
        location    = random.choice(locations)
        rows.append(f"{device},{ts.isoformat()},{temperature},{humidity},{pressure},{status},{location}")

    print("Generated 100 rows locally")
    return "\n".join(rows)
# ── Step 2: Get pre-signed URL from Spring Boot ───
def get_presigned_url(filename):
    response = requests.post(
        f"{SPRING_BOOT_URL}/api/upload/presigned-url",
        json={
            "filename": filename,
            "contentType": "text/csv"
        }
    )
    response.raise_for_status()
    return response.json()

# ── Step 3: Upload CSV directly to S3 ────────────
def upload_to_s3(presigned_url, csv_data):
    response = requests.put(
        presigned_url,
        data=csv_data.encode("utf-8"),
        headers={"Content-Type": "text/csv"}
    )
    response.raise_for_status()
    print(f"Uploaded successfully — HTTP {response.status_code}")

# ── Main ──────────────────────────────────────────
def main():
    print("Generating CSV via ChatGPT...")
    csv_data = generate_csv()
    print(f"Generated {csv_data.count(chr(10))} rows")

    # Save locally too
    with open("sensor_data.csv", "w") as f:
        f.write(csv_data)
    print("Saved locally as sensor_data.csv")

    print("Getting pre-signed URL...")
    presign = get_presigned_url("sensor_data.csv")
    print(f"S3 key: {presign['s3Key']}")

    print("Uploading to S3...")
    upload_to_s3(presign['uploadUrl'], csv_data)

    print(f"\nDone! File is at s3://{presign['bucket']}/{presign['s3Key']}")

if __name__ == "__main__":
    main()