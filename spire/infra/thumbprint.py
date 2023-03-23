import hashlib
import json
import socket
import ssl
import sys

input = json.load(sys.stdin)

contextInstance = ssl.SSLContext(ssl.PROTOCOL_TLS)

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(1)
wrappedSocket = contextInstance.wrap_socket(sock)

try:
    wrappedSocket.connect((input['host'], 443))
except:
    response = False
else:
    der_cert_bin = wrappedSocket.getpeercert(True)
    resp = {
        'value': hashlib.sha1(der_cert_bin).hexdigest()
    }
    print(json.dumps(resp))

wrappedSocket.close()
