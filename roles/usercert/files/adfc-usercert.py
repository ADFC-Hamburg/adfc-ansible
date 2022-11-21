#!/usr/bin/python3
import argparse
import sys
from pprint import pprint
import univention.uldap
import univention.config_registry
from jinja2.nativetypes import NativeEnvironment
from os import chmod,mkdir,listdir,replace, symlink, walk
from os.path import isdir
from os.path import join as os_join
from random import choice
from string import ascii_letters, digits
import subprocess

SSLBASE="/etc/adfc-test-ssl" # FIXME
# SSLBASE="/etc/univention/ssl"
JINJA_OPENSSL_TEMPLATE="/usr/local/share/adfc-usercert/openssl.cnf.j2"
CA="ucsCA"

ucr = univention.config_registry.ConfigRegistry()
ucr.load()
DEFAULT_BITS=ucr.get('ssl/default/bits')

CA_PASSWORD_FILE=os_join(SSLBASE,'password')

def generate_password_file(filename):
    password=(''.join(choice(digits + ascii_letters) for i in range(8)))
    f=open(filename,'w')
    f.writelines([password])
    f.close()
    return password

def mk_config(outfile:str, password:str, name:str, days:str, ssl_email='',
    ssl_organizationalunit='', ssl_country='', ssl_state='', ssl_locality='', ssl_organization=''):
    context={
        'CA': CA,
        "sslbase": SSLBASE,
        "ssl_country": ssl_country,
        "ssl_state": ssl_state,
        "ssl_locality": ssl_locality,
        "ssl_organization": ssl_organization,
        "ssl_organizationalunit": ssl_organizationalunit,
        "ssl_email": ssl_email,
        "name": name,
        "password": password,
        "days": days
    }
    for ucr_varname in ['ssl/country', 'ssl/locality', 'ssl/state', 'ssl/organizationalunit', 'ssl/organization', 'ssl/email']:
        j2_varname=ucr_varname.replace('/','_')
        if context[j2_varname]=='':
            context[j2_varname]=ucr.get(ucr_varname,'')
    context['DEFAULT_MD']=ucr.get('ssl/default/hashfunction')
    context['DEFAULT_BITS']=ucr.get('ssl/default/bits')
    context['DEFAULT_CRL_DAYS']=ucr.get('ssl/default/days')
    pprint(context)
    file=open(JINJA_OPENSSL_TEMPLATE)
    file_content="".join(file.readlines())
    file.close()
    env = NativeEnvironment()
    env.filters['_escape']=_escape
    t = env.from_string(file_content)
    result = t.render(context)
    outf=open(outfile,'w')
    outf.write(result)
    outf.close()
    chmod(outfile, 0o600)

def openssl(*args):
    print('openssl "%s"' % ("\" \"".join(args)))
    fargs=['openssl']+args
    rtn=subprocess.run(fargs,capture_output=True)
    return rtn

def _escape(inp:str):
    return inp.replace('\"','\\\"').replace('$', '\\$')

def move_cert(path):
    dest_dir=os_join(SSLBASE,CA,'certs')
    dir_content=listdir(path)
    for filebasename in dir_content:
        if filebasename.endswith('.pem'):
            filename=os_join(path,filebasename)
            out=subprocess.run(["openssl", "x509", "-hash",
                "-noout",
                "-in", filename], capture_output=True)
            hash=out.stdout.decode('utf-8').strip()
            dest_content=listdir(dir_content)
            count=0
            symlink_dest="%s.%d" % (hash,count)
            while symlink_dest in dest_content:
                count=count+1
                symlink_dest="%s.%d" % (hash,count)
            replace(filename, dest_dir)
            symlink(filebasename,os_join(dest_dir,symlink_dest))

def fix_permissions(path):
    for dirpath, subdirs, files in walk(path):
        for file in files:
            chmod(os_join(dirpath,file),0o400)
        chmod(dirpath,0x500)

def sign_cert(path, priv_key, req, days, username):
    global_openssl_cnf=os_join(SSLBASE,"openssl.cnf")
    cert= os_join(path, 'cert.pem')
    cert_der = os_join(path, 'cert.cer')
    owner_pw_file=os_join(path,"%s-p12-password.txt" % (username))
    owner_p12= os_join(path,'%s.p12' % (username))
    ca_file= os_join(SSLBASE,CA,"CAcert.pem")
    openssl('ca',
        '-batch',
        '-config',global_openssl_cnf,
        '-days', days,
        '-in', req,
        '-out', cert,
        '-passin', ("file:%s" % CA_PASSWORD_FILE))
    openssl('x509',
        '-outform','der',
        '-in',cert,
        '-out', cert_der)
    generate_password_file(owner_pw_file)
    openssl('pkcs12', '-export',
        '-in', cert, '-inkey', priv_key,
        '-chain', '-CAfile', ca_file,
        '-out', owner_p12,
        '-passout','file:%s' % (owner_pw_file))

def generate(user):
    # FIXME Revoc if there
    # FIXME chdir
    path=os_join(SSLBASE,'user', user['username'])
    if not isdir(path):
        mkdir(path,0o500)
    openssl_cnf=os_join(path,"openssl.cnf")
    days=ucr.get('ssl/usercert/days')
    mk_config(openssl_cnf, '', user['cn'], days, user['mail'])
    priv_key=os_join(path,'private.key')
    req=os_join(path,'req.pem')
    openssl('genrsa',
        '-out',priv_key,
        DEFAULT_BITS)
    openssl('req','-batch',
        '-config', openssl_cnf,
        '-new',
        '-key',priv_key,
        '-out',req)
    sign_cert(path, priv_key, req, days, user)
    move_cert("%s/%s/newcerts/" % (SSLBASE,CA))
    fix_permissions(path)

def status(user):
    pprint(user)
    pass

def renew(username):
    pass

def revoke(username):
    pass

def ldap_search_user(username):
    try:
        lo = univention.uldap.getMachineConnection()
    except Exception as e:
        print('ERROR: authentication error: %s' % str(e))
        sys.exit(1)
    results = lo.search(filter='(uid=%s)' % username, attr=['uid', 'cn', 'mailPrimaryAddress'])
    if len(results)==0:
        print('ERROR: User %s not found' % username)
        sys.exit(1)
    if len(results)>1:
        print('ERROR: More than one user with name %s found' % username)
        sys.exit(1)
    assert(len(results)==1)
    userobj={ 'username': username}
    for dn, attrs in results:
        userobj['dn']=dn
        userobj['cn']=attrs['cn'][0].decode("UTF-8")
        userobj['mail']=attrs['mailPrimaryAddress'][0].decode("UTF-8")
    return userobj

def main():
    parser = argparse.ArgumentParser(
        prog = 'adfc-usercert',
        description = 'Generate, renew and revoke usercerts',
        epilog = 'Thanks for riding a bike')
    parser.add_argument('username',
        help="Username of the user to do the action")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-g', '--generate',
        dest='action', action='store_const', const=generate,
        help="Generates a new certificate")
    group.add_argument('-s', '--status',
        dest='action', action='store_const', const=status,
        help="Shows status of the user cerificate")
    group.add_argument('-r', '--renew',
        dest='action', action='store_const', const=renew,
        help="Renew certificate")
    group.add_argument('--revoke',
        dest='action', action='store_const', const=revoke,
        help="Revoke the certificate.")

    args = parser.parse_args()
    userobj=ldap_search_user(args.username)
    args.action(userobj)

if __name__ == "__main__":
    main()