# how to build exe using py3.5:
#   sudo python3.5 -m pip install pyinstaller
#   pyinstaller --onefile ngrokserver.py

import http.server
import socketserver
import sys
import requests
import json
import os


'''
from threading import Thread
class myHandler(SimpleHTTPRequestHandler):
   def do_GET(self):
       self.send_response(301)
       local_redirect_port = self.server.server_address[1]
       url = redirect_urls[local_redirect_port]
       self.send_header('Location', url)
       self.end_headers()
'''

def http_server(local_path, port=80):
    os.chdir(local_path)
    handler = socketserver.TCPServer(("", port), http.server.SimpleHTTPRequestHandler)
    handler.serve_forever()

def save_mapping_frame(tunnel_url, local_path):
    result = json.loads(requests.session().get(tunnel_url).text)#"http://localhost:4040/api/tunnels"
    for t in result["tunnels"]:
        print(t["config"]["addr"], "->", t["public_url"])
        if t["proto"] == "https":
            name = t["name"]
            url = t["public_url"]
            print("create page:", name + ".htm for", t["public_url"])
            with open(local_path + "/" + name + ".htm", "w") as f:
                f.write('''<!DOCTYPE html>
<html>
<head>
<title>{name}</title>
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
<style>
html,body        {{height:100%; width:100%; margin:0;}}
.h_iframe iframe {{height:100%; width:100%;}}
.h_iframe        {{height:100%; width:100%;}}
</style>
</head>
<body><div class="h_iframe"><iframe src="{url}" frameborder="0" allowfullscreen></iframe></div></body>
</html>
'''.format(url=url, name=name))


def save_mapping_page(tunnel_url, local_path):
    result = json.loads(requests.session().get(tunnel_url).text)#"http://localhost:4040/api/tunnels"
    for t in result["tunnels"]:
        print(t["config"]["addr"], "->", t["public_url"])
        if t["proto"] == "https":
            name = t["name"]
            url = t["public_url"]
            print("create page:", name + ".htm for", t["public_url"])
            with open(local_path + "/" + name + ".htm", "w") as f:
                f.write('''<!DOCTYPE html>
<html><head><title>{name}</title>
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
<meta http-equiv = "refresh" content = "0;url={url}"/></head>
<body><p>{name}</p></body>
</html>'''.format(url=url, name=name))

if len(sys.argv) < 2:
    print("usage: function token service1=port1:service2=port2 user:password yml_path")
    print("for example: config token name1=8443:name2=6901 user:password ~/ngrok.yml")
    print("usage: function port_number local_path tunnel_url")
    print("for example: server 80 ~/ngrokweb http://localhost:4040/api/tunnels")
    exit()

function = sys.argv[1]

if function == "server":
    port = int(sys.argv[2])
    local_path = os.path.expanduser("~/ngrokweb")
    if len(sys.argv) > 3:
        local_path = os.path.expanduser(sys.argv[3])
    if not os.path.exists(local_path):
        os.mkdir(local_path)
    tunnel_url = "http://localhost:4040/api/tunnels"
    if len(sys.argv) > 4:
        tunnel_url = sys.argv[4]

    save_mapping_page(tunnel_url, local_path)
    http_server(local_path, port)

elif function == "config":
    token = sys.argv[2]

    if len(sys.argv) > 3:
        service_port = sys.argv[3]

    user_password = ""
    if len(sys.argv) > 4:
        user_password = sys.argv[4]

    local_path = os.path.expanduser("~/ngrok.yml")
    if len(sys.argv) > 5:
        local_path = os.path.expanduser(sys.argv[5])

    yml_config = """authtoken: {token}
tunnels:""".format(token=token)
    for sp in service_port.split(":"):
        name = sp.split("=")[0]
        port = sp.split("=")[1]
        yml_config += """
  {name}:
    proto: http
    addr: {port}""".format(name=name, port=port)
        if user_password != "":
            user=user_password.split(":")[0]
            password=user_password.split(":")[1]
            yml_config += """
    auth: \"{user}:{password}\"""".format(user=user, password=password)

    with open(local_path, "w") as f:
        f.write(yml_config)
