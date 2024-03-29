#!/usr/bin/python3
import argparse
import logging
import subprocess
import sys
from datetime import datetime
from os import chmod, listdir, makedirs, mkdir, replace, symlink, walk
from os.path import isdir
from os.path import join as os_join
from pprint import pformat
from random import choice
from shutil import copyfile
from string import ascii_letters, digits

import univention.config_registry
import univention.uldap
from jinja2.nativetypes import NativeEnvironment

logging.basicConfig(
    filename="/var/log/adfc/usercert.log",
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s",
)
# SSLBASE="/etc/adfc-test-ssl" # Zum testen, Achtung Pfade in
# /etc/adfc-test-ssl/openssl.cnf anpassen
SSLBASE = "/etc/univention/ssl"
JINJA_OPENSSL_TEMPLATE = "/usr/local/share/adfc-usercert/openssl.cnf.j2"
CA = "ucsCA"
FROM_EMAIL = "it-support@hamburg.adfc.de"
NEW_CERT_EMAIL = """
AUTOMATISCH ERZEUGTE E-MAIL

Für dich wurde ein Zertifikat für den Remote-Zugang erstellt.

Dieses liegt unter:

%s

und muss von dir auf einem sicheren Weg (möglichst per USB Stick) zu dir nach Hause
kopiert werden.

Das Passwort für das Zertifikat lautet:

%s

Eine Anleitung zum Einspielen findet sich unter

https://wiki.hamburg.adfc.de/doku.php?id=ak-pc:zugriff_von_aussen_ueber_zertifikat

Bitte lösche diese E-Mail und sämtliche Kopien des Zertifikats nachdem du das Zertifikat
eingespielt hast.
"""

ucr = univention.config_registry.ConfigRegistry()
ucr.load()
DEFAULT_BITS = ucr.get("ssl/default/bits")

CA_PASSWORD_FILE = os_join(SSLBASE, "password")


def get_cn_from_cert_dn(dn):
    for dn_part in dn.split("/"):
        if dn_part.upper().startswith("CN="):
            return dn_part[3:]  # Zeichenkette ohne die ersten drei Zeichen
    return None


def get_valid_cert(cn):
    now_str = "%sZ" % datetime.utcnow().strftime("%y%m%d%H%M%S")
    filename = os_join(SSLBASE, CA, "index.txt")
    index_file = open(filename, "r")
    lines = index_file.readlines()
    index_file.close()
    for line in lines[::-1]:
        (
            status,
            expire_date,
            revoce_date,
            serial,
            filename,
            cert_dn,
        ) = line.strip().split("\t")
        if (
            status == "V"
            and get_cn_from_cert_dn(cert_dn) == cn
            and now_str < expire_date
        ):
            return serial
    return None


def has_valid_cert(cn):
    return get_valid_cert(cn) is not None


def generate_password_file(filename):
    password = "".join(choice(digits + ascii_letters) for i in range(8))
    f = open(filename, "w")
    f.writelines([password])
    f.close()
    return password


def mk_config(
    outfile: str,
    password: str,
    name: str,
    days: str,
    ssl_email="",
    ssl_organizationalunit="",
    ssl_country="",
    ssl_state="",
    ssl_locality="",
    ssl_organization="",
):
    context = {
        "CA": CA,
        "sslbase": SSLBASE,
        "ssl_country": ssl_country,
        "ssl_state": ssl_state,
        "ssl_locality": ssl_locality,
        "ssl_organization": ssl_organization,
        "ssl_organizationalunit": ssl_organizationalunit,
        "ssl_email": ssl_email,
        "name": name,
        "password": password,
        "days": days,
    }
    for ucr_suffix in [
        "country",
        "locality",
        "state",
        "organizationalunit",
        "organization",
        "email",
    ]:
        ucr_varname = "ssl/usercert/default/%s" % ucr_suffix
        j2_varname = "ssl_%s" % ucr_suffix
        if context[j2_varname] == "":
            context[j2_varname] = ucr.get(ucr_varname, "")
    context["DEFAULT_MD"] = ucr.get("ssl/default/hashfunction")
    context["DEFAULT_BITS"] = ucr.get("ssl/default/bits")
    context["DEFAULT_CRL_DAYS"] = ucr.get("ssl/default/days")
    file = open(JINJA_OPENSSL_TEMPLATE)
    file_content = "".join(file.readlines())
    file.close()
    env = NativeEnvironment()
    env.filters["_escape"] = _escape
    t = env.from_string(file_content)
    result = t.render(context)
    outf = open(outfile, "w")
    outf.write(result)
    outf.close()
    chmod(outfile, 0o600)


def run_subrprocess(fargs, env):
    rtn = subprocess.run(fargs, capture_output=True, env=env)
    if rtn.returncode == 0:
        logging.info("stdout: %s" % rtn.stdout.decode("utf-8"))
        logging.info("stderr: %s" % rtn.stdout.decode("utf-8"))
        logging.info("rtncode %d" % rtn.returncode)
    else:
        logging.error("stdout: %s" % rtn.stdout.decode("utf-8"))
        logging.error("stderr: %s" % rtn.stdout.decode("utf-8"))
        logging.error("rtncode %d" % rtn.returncode)
        print("Stdout:")
        print(rtn.stdout.decode("utf-8"))
        print("Stderr:")
        print(rtn.stderr.decode("utf-8"))
        print("Returncode: %d", rtn.returncode)
        sys.exit(2)
    # else
    return rtn


def run_userscript(action: str, user):
    logging.info("userscript %s %s" % (action, user["uid"]))
    fargs = [
        "/usr/lib/univention-ssl-usercert/copy-zertifikat",
        action,
        user["dn"],
        user["uid"],
        "/etc/univention/ssl/user",
    ]
    enviroment = {
        "HOME": "/root",
    }
    return run_subrprocess(fargs, enviroment)


def openssl(*args):
    logging.info('openssl "%s"' % ('" "'.join(args)))
    fargs = ["openssl"] + list(args)
    enviroment = {
        "HOME": "/root",
        "DEFAULT_CRL_DAYS": ucr.get("ssl/default/days"),
        "DEFAULT_MD": ucr.get("ssl/default/hashfunction"),
        "DEFAULT_BITS": DEFAULT_BITS,
    }
    return run_subrprocess(fargs, enviroment)


def send_mail(recipient: str, subject: str, message: str):
    global FROM_EMAIL
    mailx_cmd = ["mailx", "-s", subject, "-r", FROM_EMAIL, recipient]
    logging.info("Sending E-mail to %s ", recipient)
    # Sende die E-Mail
    try:
        mailx_process = subprocess.Popen(mailx_cmd, stdin=subprocess.PIPE)
        mailx_process.communicate(input=message.encode())
        logging.info("Sending E-mail success %s ", recipient)
    except subprocess.CalledProcessError as e:
        logging.error("Error sending e-mail ", e)


def _escape(inp: str):
    return inp.replace('"', '\\"').replace("$", "\\$")


def move_cert(path):
    dest_dir = os_join(SSLBASE, CA, "certs")
    dir_content = listdir(path)
    for filebasename in dir_content:
        if filebasename.endswith(".pem"):
            filename = os_join(path, filebasename)
            out = subprocess.run(
                ["openssl", "x509", "-hash", "-noout", "-in", filename],
                capture_output=True,
            )
            hash = out.stdout.decode("utf-8").strip()
            dest_content = listdir(dest_dir)
            count = 0
            symlink_dest = "%s.%d" % (hash, count)
            while symlink_dest in dest_content:
                count = count + 1
                symlink_dest = "%s.%d" % (hash, count)
            replace(filename, os_join(dest_dir, filebasename))
            symlink(filebasename, os_join(dest_dir, symlink_dest))


def fix_permissions(path):
    for dirpath, subdirs, files in walk(path):
        for file in files:
            chmod(os_join(dirpath, file), 0o400)
        chmod(dirpath, 0x500)


def sign_cert(path, priv_key, req, days, username: str):
    global_openssl_cnf = os_join(SSLBASE, "openssl.cnf")
    cert = os_join(path, "cert.pem")
    cert_der = os_join(path, "cert.cer")
    owner_pw_file = os_join(path, "%s-p12-password.txt" % (username))
    owner_p12 = os_join(path, "%s.p12" % (username))
    ca_file = os_join(SSLBASE, CA, "CAcert.pem")
    openssl(
        "ca",
        "-batch",
        "-config",
        global_openssl_cnf,
        "-days",
        days,
        "-in",
        req,
        "-out",
        cert,
        "-passin",
        ("file:%s" % CA_PASSWORD_FILE),
    )
    openssl("x509", "-outform", "der", "-in", cert, "-out", cert_der)
    generate_password_file(owner_pw_file)
    openssl(
        "pkcs12",
        "-export",
        "-in",
        cert,
        "-inkey",
        priv_key,
        "-chain",
        "-CAfile",
        ca_file,
        "-out",
        owner_p12,
        "-passout",
        "file:%s" % (owner_pw_file),
    )


def generate(user):
    if has_valid_cert(user["uid"]):
        print("ERROR: There is one valid cert, please revoke first")
        logging.error("There is one valid cert, please revoke first")
        sys.exit(1)
    path = os_join(SSLBASE, "user", user["uid"])
    if not isdir(path):
        mkdir(path, 0o500)
    openssl_cnf = os_join(path, "openssl.cnf")
    days = ucr.get("ssl/usercert/days")
    mk_config(openssl_cnf, "", user["uid"], days, user["mail"])
    priv_key = os_join(path, "private.key")
    req = os_join(path, "req.pem")
    openssl("genrsa", "-out", priv_key, DEFAULT_BITS)
    openssl(
        "req", "-batch", "-config", openssl_cnf, "-new", "-key", priv_key, "-out", req
    )
    sign_cert(path, priv_key, req, days, user["uid"])
    move_cert("%s/%s/newcerts/" % (SSLBASE, CA))
    fix_permissions(path)
    zuid = user["uid"]
    zhome = "/home/%s/adfc-zertifikate" % zuid
    pwfile = f"/etc/univention/ssl/user/{zuid}/{zuid}-p12-password.txt"
    password = open(pwfile).read().strip()
    makedirs(zhome, mode=0o700, exist_ok=True)
    zfile = f'{zhome}/{zuid}{datetime.now().strftime("%Y%m%d")}.p12'
    subprocess.run(["cp", f"//etc/univention/ssl/user/{zuid}/{zuid}.p12", zfile])
    subprocess.run(["chown", "-R", zuid, zhome])
    send_mail(user["mail"], "Neues Zertikat", NEW_CERT_EMAIL % (zhome, password))
    print("Userzertifikat erstellt, siehe: %s" % path)


def get_openssl_status(username):
    rtn = {}
    serial = get_valid_cert(username)
    if serial is None:
        return None
    # else
    cert = os_join(SSLBASE, CA, "certs", ("%s.pem" % serial))
    out = openssl("x509", "-in", cert, "-text", "-noout")
    keywords = [
        "Not Before:",
        "Not After :",
        "Public Key Algorithm:",
        "Subject:",
        "RSA Public-Key:",
        "Serial Number:",
        "Issuer:",
    ]
    for line in out.stdout.decode("utf-8").split("\n"):
        for keyword in keywords:
            if keyword in line:
                line_parts = line.strip().split(":")
                rtn[keyword.replace(":", "").strip()] = ":".join(line_parts[1:])
    return rtn


def status(user):
    out = get_openssl_status(user["uid"])
    if out is None:
        print("Kein Zertifikat für den User %s gefunden." % user["uid"])
        logging.info("Kein Zertifikat für den User %s gefunden." % user["uid"])
        return
    # else
    print("Gültiges Zertifikat gefunden:\n")
    for key in out.keys():
        print("%-21s%s" % (key, out[key]))


def revoke(user):
    serial = get_valid_cert(user["uid"])
    global_openssl_cnf = os_join(SSLBASE, "openssl.cnf")
    {
        "HOME": "/root",
        "DEFAULT_CRL_DAYS": ucr.get("ssl/default/days"),
        "DEFAULT_MD": ucr.get("ssl/default/hashfunction"),
        "DEFAULT_BITS": DEFAULT_BITS,
    }
    if serial is None:
        print("ERROR: There no valid cert to revoke.")
        logging.error("There no valid cert to revoke.")
        sys.exit(1)
    cert = os_join(SSLBASE, CA, "certs", ("%s.pem" % serial))
    openssl(
        "ca",
        "-config",
        global_openssl_cnf,
        "-revoke",
        cert,
        "-passin",
        ("file:%s" % CA_PASSWORD_FILE),
    )
    gencrl()
    print("User revoked")


def gencrl():
    global_openssl_cnf = os_join(SSLBASE, "openssl.cnf")
    pem = os_join(SSLBASE, CA, "crl", "crl.pem")
    der = os_join(SSLBASE, CA, "crl", ("%s.crl" % CA))
    der_www = os_join("/var/www", ("%s.crl" % CA))
    openssl(
        "ca",
        "-config",
        global_openssl_cnf,
        "-gencrl",
        "-out",
        pem,
        "-passin",
        ("file:%s" % CA_PASSWORD_FILE),
    )
    openssl("crl", "-in", pem, "-out", der, "-inform", "pem", "-outform", "der")
    copyfile(der, der_www)
    chmod(der_www, 0o644)


def cron(user):
    today = datetime.now()
    output = ""
    warndays = 30
    for directory in listdir("/etc/univention/ssl/user"):
        status = get_openssl_status(directory)
        if status is not None:
            date = datetime.strptime(
                status["Not After"].strip(), "%b %d %H:%M:%S %Y %Z"
            )
            days = (date - today).days
            if days <= warndays:
                output = output + "* %s in %d Tagen: %s\n" % (directory, days, date)
    if output != "":
        head = "Moin,\nfolgende Zertifikate laufen demnächst ab:\n"
        mailingliste = open("/etc/ansible/secrets/mailingliste.txt").read().strip()
        send_mail(mailingliste, "ADFC Zertifikate laufen demnächst ab", head + output)


def ldap_search_user(username):
    try:
        lo = univention.uldap.getMachineConnection()
    except Exception as e:
        print("ERROR: authentication error: %s" % str(e))
        logging.error("authentication error %s", str(e))
        sys.exit(1)
    results = lo.search(
        filter="(uid=%s)" % username, attr=["uid", "cn", "mailPrimaryAddress"]
    )
    if len(results) == 0:
        print("ERROR: User %s not found" % username)
        logging.error("User not found")
        sys.exit(1)
    if len(results) > 1:
        print("ERROR: More than one user with name %s found" % username)
        logging.error("More than one user found")
        sys.exit(1)
    assert len(results) == 1
    userobj = {"uid": username}
    for dn, attrs in results:
        userobj["dn"] = dn
        userobj["cn"] = attrs["cn"][0].decode("UTF-8")
        userobj["mail"] = attrs["mailPrimaryAddress"][0].decode("UTF-8")
    return userobj


def main():
    parser = argparse.ArgumentParser(
        prog="adfc-usercert",
        description="Generate, renew and revoke usercerts",
        epilog="Thanks for riding a bike",
    )
    parser.add_argument("username", help="Username of the user to do the action")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-g",
        "--generate",
        dest="action",
        action="store_const",
        const=generate,
        help="Generates a new certificate",
    )
    group.add_argument(
        "-s",
        "--status",
        dest="action",
        action="store_const",
        const=status,
        help="Shows status of the user cerificate",
    )
    #    group.add_argument('-r', '--renew',
    #        dest='action', action='store_const', const=renew,
    #        help="Renew certificate")
    group.add_argument(
        "--revoke",
        dest="action",
        action="store_const",
        const=revoke,
        help="Revoke the certificate.",
    )
    group.add_argument(
        "--cron",
        dest="action",
        action="store_const",
        const=cron,
        help="Do cron things.",
    )
    args = parser.parse_args()
    logging.debug("Aufruf %s" % pformat(args))
    if args.username == "ALL":
        userobj = None
    else:
        userobj = ldap_search_user(args.username)
    args.action(userobj)


if __name__ == "__main__":
    main()
