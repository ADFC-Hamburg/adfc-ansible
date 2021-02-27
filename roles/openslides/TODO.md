== PASSWORT SETZEN ==
/usr/local/share/openslides/py-venv-3.2/lib/python3.7/site-packages/django/contrib/auth/hashers.py

from django.contrib.auth.hashers import make_password

admin.default_password = "admin"
admin.password = make_password(admin.default_password)
