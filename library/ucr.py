#!/usr/bin/python
# -*- coding: utf-8 -*-

#  Copyright (c) 2019 by Sven Anders <ansible2019@sven.anders.hamburg>
#



ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = '''
---
module: ucr
version_added: "2.7.5"
short_description: "Sets values in Univention Configuration Registry"
extends_documentation_fragment: ''
description:
  - Sets and Unsets values of keys in Univention Configuration Registry
notes:
  - none
requirements:
  - Python >= 2.6
  - Univention
author: Sven Anders
options:
  state:
    required: false
    default: "present"
    choices: [ present, absent ]
    description:
      - Whether the ucr entries are present or not.
  values:
    description:
    - 'Desired key+values in a dict of the ucr to set'
    required: true
'''

EXAMPLES = '''
# Create a DNS record on a UCS
- ucr:
    values:
     interfaces/eth0/address: 192.168.1.42
     interfaces/eth0/netmask: 255.255.255.0
     interfaces/eth0/network: 192.168.1.0
     gateway: 192.168.1.1
'''

RETURN = '''
    "changed": true,
    "num_changed": 3,
    "values": {
        "interfaces/eth0/address": {
            "changed": true,
            "new_value": "192.168.1.42",
            "old_value": "192.168.99.12"
        },
        "interfaces/eth0/netmask": {
            "changed": false,
            "new_value": "255.255.255.0",
            "old_value": "255.255.255.0"
        },
        "interfaces/eth0/network": {
            "changed": true,
            "new_value": "192.168.1.0",
            "old_value": "192.168.99.0"
        },
        "gateway": {
            "changed": true,
            "new_value": "192.168.1.1",
            "old_value": "192.168.99.1"
        },
    }
'''

from ansible.module_utils.basic import AnsibleModule

HAVE_UNIVENTION = False
try:
    import univention.config_registry
    HAVE_UNIVENTION = True
except ImportError:
    pass

def get_value(ucr, key):
    ''' Find out current value '''
    if key in ucr:
        return ucr[key]
    return None

def set_value(ucr, key, value):
    ''' Set value for key '''
    ucr[key]=value

def unset(ucr, key):
    ''' Unset ucr for key '''
    del ucr[key]

def handle_item(module, ucr, key, value):
    old_value = get_value(ucr, key)
    changed = old_value != value

    if changed and not module.check_mode:
        if value is None:
           unset(ucr, key)
        else:
           set_value(ucr, key, value)
    return {
        'old_value': old_value,
        'new_value': value,
        'changed': changed
        };

def main():
    module = AnsibleModule(
        argument_spec = dict(
            values = dict(type='dict', required=True),
            state= dict(default='present', choices=['present', 'absent']),
        ),
        supports_check_mode=True
    )

    if not HAVE_UNIVENTION:
        module.fail_json(msg="This module requires univention python bindings")

    ucr = univention.config_registry.ConfigRegistry()
    ucr.load()
    rtn = {}
    glob_changed = False
    num_changed = 0
    present = (module.params['state'] == 'present')
    for key, value in module.params['values'].items():
        if not present:
            value = None
        rtn[key] = handle_item(module, ucr, key, value)
        if rtn[key]['changed']:
            num_changed= num_changed+1
            glob_changed=True
    if not module.check_mode:
        ucr.save()
    return module.exit_json(
        changed = glob_changed,
        values = rtn,
        num_changed = num_changed,
    )



main()
