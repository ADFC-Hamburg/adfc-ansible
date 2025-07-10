#!/usr/bin/python3
from flask import Flask, Response
import paramiko
import threading
import time
import json
import os

app = Flask(__name__)
data_store = {}

import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)


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
            client.connect('192.168.123.53', username='root', pkey=key)  # Update with your username

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
        time.sleep(60)  

@app.route('/metrics')
def metrics():
    # Prepare metrics in Prometheus format
    cpu_data = data_store.get('stat', {}).get('cpu', {})
 
    metrics = f"""# HELP freifunk_total_clients Total number of clients
# TYPE freifunk_total_clients gauge
freifunk_total_clients {data_store.get('clients', {}).get('wifi', 0)}

# HELP freifunk_wlan_current_connections current WLAN connections
# TYPE freifunk__wlan_current_connections gauge
freifunk_wlan_current_connections{{wlan="2.4 GHz"}} {data_store.get('clients', {}).get('wifi24', 0)}
freifunk_wlan_current_connections{{wlan="5 Ghz"}} {data_store.get('clients', {}).get('wifi5', 0)}

# HELP traffic_rx_bytes Total received bytes
# TYPE traffic_rx_bytes counter
freifunk_traffic_rx_bytes {data_store.get('traffic', {}).get('rx', {}).get('bytes', 0)}

# HELP traffic_tx_packets Total transmited bytes
# TYPE traffic_tx_packets counter
freifunk_traffic_tx_bytes {data_store.get('traffic', {}).get('tx', {}).get('bytes', 0)}

# HELP freifunk_cpu_seconds_total Seconds the cpus spent in each mode.
# TYPE freifunk_cpu_seconds_total counter
freifunk_cpu_seconds_total{{cpu="0",mode="idle"}} {cpu_data.get('idle', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="iowait"}} {cpu_data.get('iowait', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="irq"}} {cpu_data.get('irq', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="nice"}} {cpu_data.get('nice', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="softirq"}} {cpu_data.get('softirq', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="system"}} {cpu_data.get('system', 0)}
freifunk_cpu_seconds_total{{cpu="0",mode="user"}} {cpu_data.get('user', 0)}

# HELP freifunk_node_load load average.
# TYPE freifunk_node_load gauge
freifunk_node_load {data_store.get('loadavg', 0)}
"""

    return Response(metrics, mimetype='text/plain')

if __name__ == '__main__':
    # Start the data fetching in a separate thread
    threading.Thread(target=fetch_data, daemon=True).start()
    app.run(port=5000)

