#!/usr/bin/python3
import argparse
import sys
import univention.uldap
import univention.config_registry
from jinja2.nativetypes import NativeEnvironment
from os import chmod,mkdir,listdir,replace, symlink, walk
from os.path import isdir
from os.path import join as os_join
from random import choice
from string import ascii_letters, digits
import subprocess
from datetime import datetime
from shutil import copyfile
import logging
from pprint import pformat

logging.basicConfig(filename='/var/log/adfc/usercert.log',
    level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s')
# SSLBASE="/etc/adfc-test-ssl" # Zum testen, Achtung Pfade in /etc/adfc-test-ssl/openssl.cnf anpassen
SSLBASE="/etc/univention/ssl"
JINJA_OPENSSL_TEMPLATE="/usr/local/share/adfc-usercert/openssl.cnf.j2"
CA="ucsCA"

ucr = univention.config_registry.ConfigRegistry()
ucr.load()
DEFAULT_BITS=ucr.get('ssl/default/bits')

CA_PASSWORD_FILE=os_join(SSLBASE,'password')

def get_cn_from_cert_dn(dn):
    for dn_part in dn.split("/"):
        if dn_part.upper().startswith('CN='):
            return dn_part[3:] # Zeichenkette ohne die ersten drei Zeichen
    return None

def get_valid_cert(cn):
    now_str="%sZ" % datetime.utcnow().strftime('%y%m%d%H%M%S')
    filename=os_join(SSLBASE,CA,'index.txt')
    index_file=open(filename,'r')
    lines=index_file.readlines()
    index_file.close()
    for line in lines[::-1]:
        (status,expire_date,revoce_date,serial,filename,cert_dn)=line.strip().split('\t')
        if status=='V' and get_cn_from_cert_dn(cert_dn)==cn and now_str<expire_date:
            return serial
    return None

def has_valid_cert(cn):
    return get_valid_cert(cn)!=None

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
    for ucr_suffix in ['country', 'locality', 'state', 'organizationalunit', 'organization', 'email']:
        ucr_varname='ssl/usercert/default/%s' % ucr_suffix
        j2_varname='ssl_%s' % ucr_suffix
        if context[j2_varname]=='':
            context[j2_varname]=ucr.get(ucr_varname,'')
    context['DEFAULT_MD']=ucr.get('ssl/default/hashfunction')
    context['DEFAULT_BITS']=ucr.get('ssl/default/bits')
    context['DEFAULT_CRL_DAYS']=ucr.get('ssl/default/days')
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
    logging.info('openssl "%s"' % ("\" \"".join(args)))
    fargs=['openssl']+list(args)
    enviroment={
        'HOME': '/root',
        'DEFAULT_CRL_DAYS': ucr.get('ssl/default/days'),
        'DEFAULT_MD': ucr.get('ssl/default/hashfunction'),
        'DEFAULT_BITS': DEFAULT_BITS
    }
    rtn=subprocess.run(fargs,capture_output=True, env=enviroment)
    if (rtn.returncode==0):
        logging.info('stdout: %s' %rtn.stdout.decode('utf-8'))
        logging.info('stderr: %s' %rtn.stdout.decode('utf-8'))
        logging.info('rtncode %d' %rtn.returncode)
    else:
        logging.error('stdout: %s' %rtn.stdout.decode('utf-8'))
        logging.error('stderr: %s' %rtn.stdout.decode('utf-8'))
        logging.error('rtncode %d' %rtn.returncode)
        print('Stdout:')
        print(rtn.stdout.decode('utf-8'))
        print('Stderr:')
        print(rtn.stderr.decode('utf-8'))
        print('Returncode: %d',rtn.returncode)
        sys.exit(2)
    # else
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
            dest_content=listdir(dest_dir)
            count=0
            symlink_dest="%s.%d" % (hash,count)
            while symlink_dest in dest_content:
                count=count+1
                symlink_dest="%s.%d" % (hash,count)
            replace(filename, os_join(dest_dir,filebasename))
            symlink(filebasename,os_join(dest_dir,symlink_dest))

def fix_permissions(path):
    for dirpath, subdirs, files in walk(path):
        for file in files:
            chmod(os_join(dirpath,file),0o400)
        chmod(dirpath,0x500)

def sign_cert(path, priv_key, req, days, username:str):
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
    if has_valid_cert(user['uid']):
        print('ERROR: There is one valid cert, please revoke first')
        logging.error('There is one valid cert, please revoke first')
        sys.exit(1)
    path=os_join(SSLBASE,'user', user['uid'])
    if not isdir(path):
        mkdir(path,0o500)
    openssl_cnf=os_join(path,"openssl.cnf")
    days=ucr.get('ssl/usercert/days')
    mk_config(openssl_cnf, '', user['uid'], days, user['mail'])
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
    sign_cert(path, priv_key, req, days, user['uid'])
    move_cert("%s/%s/newcerts/" % (SSLBASE,CA))
    fix_permissions(path)
    print('Userzertifikat erstellt, siehe: %s' % path)
def status(user):
    serial=get_valid_cert(user['uid'])
    if serial==None:
        print('Kein Zertifikat für den User %s gefunden.' %user['uid'])
        logging.info('Kein Zertifikat für den User %s gefunden.' %user['uid'])
        return
    # else
    print('Gültiges Zertifikat gefunden:\n')
    cert=os_join(SSLBASE,CA,'certs',('%s.pem' % serial))
    out=openssl('x509', '-in', cert, '-text', '-noout')
    keywords=[
        'Not Before:',
        'Not After :',
        'Public Key Algorithm:',
        'Subject:',
        'RSA Public-Key:',
        'Serial Number:',
        'Issuer:'
    ]
    for line in out.stdout.decode('utf-8').split('\n'):
        for keyword in keywords:
            if keyword in line:
                line_parts=line.strip().split(':')
                print('%-21s%s' % (keyword,":".join(line_parts[1:])))


def revoke(user):
    serial=get_valid_cert(user['uid'])
    global_openssl_cnf=os_join(SSLBASE,"openssl.cnf")
    enviroment={
        'HOME': '/root',
        'DEFAULT_CRL_DAYS': ucr.get('ssl/default/days'),
        'DEFAULT_MD': ucr.get('ssl/default/hashfunction'),
        'DEFAULT_BITS': DEFAULT_BITS
    }
    if serial is None:
        print('ERROR: There no valid cert to revoke.')
        logging.error('There no valid cert to revoke.')
        sys.exit(1)
    cert=os_join(SSLBASE,CA,'certs',('%s.pem' % serial))
    openssl('ca',
        '-config', global_openssl_cnf,
        '-revoke', cert,
        '-passin', ("file:%s" % CA_PASSWORD_FILE)
    )
    gencrl()
    print('User revoked')

def gencrl():
    global_openssl_cnf=os_join(SSLBASE,"openssl.cnf")
    pem=os_join(SSLBASE,CA,'crl','crl.pem')
    der=os_join(SSLBASE,CA,'crl',('%s.crl' % CA))
    der_www=os_join('/var/www',('%s.crl' % CA))
    openssl('ca',
        '-config', global_openssl_cnf,
        '-gencrl',
        '-out', pem,
        '-passin', ("file:%s" % CA_PASSWORD_FILE)
    )
    openssl('crl',
        '-in', pem,
        '-out', der,
        '-inform', 'pem',
        '-outform', 'der'
    )
    copyfile(der,der_www)
    chmod(der_www,0o644)

def ldap_search_user(username):
    try:
        lo = univention.uldap.getMachineConnection()
    except Exception as e:
        print('ERROR: authentication error: %s' % str(e))
        logging.error('authentication error %s',str(e))
        sys.exit(1)
    results = lo.search(filter='(uid=%s)' % username, attr=['uid', 'cn', 'mailPrimaryAddress'])
    if len(results)==0:
        print('ERROR: User %s not found' % username)
        logging.error('User not found')
        sys.exit(1)
    if len(results)>1:
        print('ERROR: More than one user with name %s found' % username)
        logging.error("More than one user found")
        sys.exit(1)
    assert(len(results)==1)
    userobj={ 'uid': username}
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
#    group.add_argument('-r', '--renew',
#        dest='action', action='store_const', const=renew,
#        help="Renew certificate")
    group.add_argument('--revoke',
        dest='action', action='store_const', const=revoke,
        help="Revoke the certificate.")

    args = parser.parse_args()
    logging.debug('Aufruf %s' % pformat(args))
    userobj=ldap_search_user(args.username)
    args.action(userobj)

if __name__ == "__main__":
    main()