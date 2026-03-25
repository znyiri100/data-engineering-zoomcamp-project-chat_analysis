import subprocess
import csv
import os
import io
from datetime import datetime

# Database connection details provided by user
DOCKER_CONTAINER = "XXX"
DB_USER = "XXX"
DB_PASS = "XXX"
DB_NAME = "XXX"

# Query based on user snippets
# Filter: u.name LIKE 'demo-test%'
# Fields: user, topic, id, createdAt, attempt, response, userMessage
QUERY = """
SELECT 
    u.name AS user, 
    t.id AS topic_id, 
    cl.id, 
    cl.createdAt, 
    cl.attempt, 
    cl.response, 
    cl.userMessage
FROM conversation_log cl 
JOIN users u ON cl.userid = u.id 
JOIN topic t ON t.id = cl.topicid 
WHERE u.name LIKE 'demo-test%'
ORDER BY cl.createdAt;
"""

def run_query(query):
    # -B: batch mode (tab separated, escapes special chars)
    cmd = [
        "docker", "exec", DOCKER_CONTAINER,
        "mariadb", "-u", DB_USER, f"-p{DB_PASS}", DB_NAME,
        "-B", "-e", query
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running query: {result.stderr}")
        return None
    return result.stdout

def main():
    print("Fetching data from database...")
    output = run_query(QUERY)
    if not output:
        return

    # Use io.StringIO to let csv module handle lines
    f_in = io.StringIO(output)
    reader = csv.DictReader(f_in, delimiter='\t')
    
    data_by_month = {}
    topics = {}

    for line_num, row in enumerate(reader, start=2):
        created_at_str = row.get('createdAt')
        if not created_at_str or created_at_str == 'NULL':
            continue
            
        try:
            # createdAt might be 'YYYY-MM-DD HH:MM:SS' or 'YYYY-MM-DD HH:MM:SS.000'
            # Just take the first 7 chars for the month (YYYY-MM)
            month = created_at_str[:7]
            if len(month) != 7 or month[4] != '-':
                print(f"Warning: Invalid date format at line {line_num}: {created_at_str}")
                continue
        except Exception as e:
            print(f"Error processing date at line {line_num}: {e}")
            continue
        
        topic = row.get("topic")
        topic_id = row.get("topic_id")
        try:
            tid = int(topic_id) if topic_id not in (None, "", "NULL") else None
        except ValueError:
            tid = None
        if tid is not None and topic:
            topics[tid] = topic

        if month not in data_by_month:
            data_by_month[month] = []
        data_by_month[month].append(row)

    os.makedirs('data', exist_ok=True)
    
    for month, records in data_by_month.items():
        filename = f"data/{month}.csv"
        print(f"Writing {len(records)} records to {filename}...")
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            if records:
                # Use headers from the first record found or reader
                writer = csv.DictWriter(f, fieldnames=reader.fieldnames)
                writer.writeheader()
                writer.writerows(records)

    if topics:
        lookup_path = 'data/topic_lookup.csv'
        print(f"Writing {len(topics)} unique topics to {lookup_path}...")
        with open(lookup_path, 'w', newline='', encoding='utf-8') as f:
            lookup_writer = csv.writer(f)
            lookup_writer.writerow(['topic_id', 'topic'])
            for topic_id in sorted(topics):
                lookup_writer.writerow([topic_id, topics[topic_id]])

    print("Done!")

if __name__ == "__main__":
    main()
