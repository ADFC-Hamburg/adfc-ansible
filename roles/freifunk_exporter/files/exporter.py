#!/usr/bin/python3
from flask import Flask, Response
import paramiko
import threading
import time
import json
import os

app = Flask(__name__)
data_store = {}

def fetch_data():
    global data_store
    while True:
        try:
            # Set up SSH client
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            # Connect to the remote server using an SSH key
            private_key_path = os.path.expanduser('~/.ssh/id_rsa')  # Path to your private key
            key = paramiko.RSAKey.from_private_key_file(private_key_path)
            client.connect('192.168.250.53', username='root', pkey=key)  # Update with your username

            # Execute the command
            stdin, stdout, stderr = client.exec_command('gluon-neighbour-info -s "" -l -d ::1 -p 1001 -t 3 -r statistics')

            # Read the output
            start_time = time.time()
            while True:
                if time.time() - start_time > 3:  # Stop reading after 3 seconds
                    break

                line = stdout.readline()
                if not line:
                    break  # Exit if no more lines

                # Process each line of data
                decoded_line = line.strip()
                if decoded_line.startswith("data:"):
                    data = decoded_line[5:]  # Remove 'data: ' prefix
                    if data != "null":
                        # print("Line received:", data)  # Debug output
                        json_data = json.loads(data)  # Parse JSON
                        data_store.update(json_data)  # Update the data store

            client.close()  # Close the SSH connection

        except Exception as e:
            print(f"An error occurred: {e}")

        # Sleep before the next fetch attempt
        time.sleep(10)  # Fetch new data every 10 seconds

@app.route('/metrics')
def metrics():
    # Prepare metrics in Prometheus format
    cpu_data = data_store.get('stat', {}).get('cpu', {})
    idle_time = cpu_data.get('idle', 0)
    user_time = cpu_data.get('user', 0)
    system_time = cpu_data.get('system', 0)
    iowait_time = cpu_data.get('iowait', 0)
    # Add any other relevant CPU states if needed

    # Calculate total CPU time
    total_cpu_time = idle_time + user_time + system_time + iowait_time  # Extend if needed

    # Calculate CPU idle percentage
    cpu_idle_percentage = (idle_time / total_cpu_time) * 100 if total_cpu_time > 0 else 0

    metrics = f"""
    # HELP total_clients Total number of clients
    # TYPE total_clients gauge
    freifunk_total_clients {data_store.get('clients', {}).get('total', 0)}

    # HELP traffic_rx_packets Total received packets
    # TYPE traffic_rx_packets counter
    freifunk_traffic_rx_bytes {data_store.get('traffic', {}).get('rx', {}).get('bytes', 0)}
    freifunk_traffic_tx_bytes {data_store.get('traffic', {}).get('tx', {}).get('bytes', 0)}

    # HELP cpu_idle_percentage CPU idle time percentage
    # TYPE cpu_idle_percentage gauge
    freifunk_cpu_idle_percentage {cpu_idle_percentage}    
    """

    return Response(metrics, mimetype='text/plain')

if __name__ == '__main__':
    # Start the data fetching in a separate thread
    threading.Thread(target=fetch_data, daemon=True).start()
    app.run(port=5000)
