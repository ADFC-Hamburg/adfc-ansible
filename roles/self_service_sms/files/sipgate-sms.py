#!/usr/bin/python2.7
# -*- coding: utf-8 -*-

import os
import sys
import xmlrpclib

env = os.environ

# create XMLRPC proxy
xmlrpc_url = "https://{username}:{password}@samurai.sipgate.net/RPC2".format(username=env["sms_username"], password=env["sms_password"])
rpc_srv = xmlrpclib.ServerProxy(xmlrpc_url)

# identify myself
reply = rpc_srv.samurai.ClientIdentify({
"ClientName": "Univention Self Service (python xmlrpclib)",
"ClientVersion": "1.0",
"ClientVendor": "https://www.univention.com/"
})
print("Login success. Server reply to ClientIdentify(): ‚{}‘.".format(reply))

# create text message
msg = "Password reset token: {token}".format(token=env["selfservice_token"])
if len(msg) > 160:
  raise ValueError("Message to long: ‚{}‘.".format(msg))

# Sipgate wants phone numbers in E.164 format
num = "".join(map(lambda x: x if x.isdigit() else "", env["selfservice_address"]))
if num.startswith("00"):
  num = num[2:]
elif num.startswith("0"):
  num = "{}{}".format(env["sms_country_code"], num[1:])
else:
  pass

# send message
args = {"RemoteUri": "sip:%s@sipgate.net" % num, "TOS": "text", "Content": msg}
reply = rpc_srv.samurai.SessionInitiate(args)

if reply.get("StatusCode") == 200:
  print("Success sending token to user {}.".format(env["selfservice_username"]))
  sys.exit(0)
else:
  print("Error sending token to user {}. Sipgate returned: {}".format(env["selfservice_username"], reply))
  sys.exit(1)
