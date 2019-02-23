#!/usr/bin/python
# -*- coding: utf-8 -*-

#  Copyright (c) 2019 by Sven Anders <ansible2019@sven.anders.hamburg>
#



ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = '''
---
module: ucr_get
version_added: "2.7.5"
short_description: "Get values from Univention Configuration Registry"
extends_documentation_fragment: ''
description:
  - Gets values of keys in Univention Configuration Registry
notes:
  - none
requirements:
  - Python >= 2.6
  - Univention
author: Sven Anders
options:
  - none
'''

from ansible.module_utils.basic import AnsibleModule

HAVE_UNIVENTION = False
try:
    import univention.config_registry
    HAVE_UNIVENTION = True
except ImportError:
    pass


def main():
    module = AnsibleModule(
        argument_spec = dict(
        ),
        supports_check_mode=True
    )

    if not HAVE_UNIVENTION:
        module.fail_json(msg="This module requires univention python bindings")

    ucr = univention.config_registry.ConfigRegistry()
    ucr.load()
    rtn={}
    for key in ucr:
        rtn[key]=ucr[key]
    return module.exit_json(
        changed = False,
        ucr = rtn
    )



main()
