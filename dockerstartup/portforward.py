# sudo pip3 install pyinstaller
# how to build exe: pyinstaller --onefile portforward.py

import http.server
import socketserver
import sys
import requests
import json
from threading import Thread

class myHandler(http.server.SimpleHTTPRequestHandler):
   def do_GET(self):
       self.send_response(301)
       local_redirect_port = self.server.server_address[1]
       url = redirect_urls[local_redirect_port]
       self.send_header('Location', url)
       self.end_headers()

def http_server(target_url, port=80):
    with socketserver.TCPServer(("", port), myHandler) as handler:
        print("serving at port", port, "for url", target_url)
        handler.serve_forever()

if len(sys.argv) < 2:
    print("usage: local_source_port:local_forward_port")
    print("for example: 8443:8080;6901:8081")
    exit()

port_mapping = sys.argv[1]
tunnel_url = "http://localhost:4040/api/tunnels"
if len(sys.argv) > 2:
    tunnel_url = sys.argv[2]

def get_ngrok_mapping(url):
    ngrok_mapping = {}
    ngrok_result = requests.session().get(url)#"http://localhost:4040/api/tunnels"
    ngrok_json = json.loads(ngrok_result.text)
    for t in ngrok_json["tunnels"]:
        print(t["config"]["addr"], "->", t["public_url"])
        if t["proto"] == "https":
            local_address = t["config"]["addr"]
            local_port = local_address[local_address.rfind(":")+1:]
            ngrok_mapping[local_port] = t["public_url"]
    return ngrok_mapping

redirect_urls = {}
ngrok_mapping = get_ngrok_mapping(tunnel_url)
for m in port_mapping.split(";"):
    try:
        ma = m.split(":")
        public_url = ngrok_mapping[ma[0]]
        port = int(ma[1])
        redirect_urls[port] = public_url
        web_thread = Thread(target=http_server, args=(public_url, port))
        web_thread.start()
    except Exception as ex:
        print(ex)

