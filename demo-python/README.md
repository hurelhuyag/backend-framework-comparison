#

```sh
pip install -r requirements.txt
python manage.py collectstatic --noinput
python manage.py migrate
gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 4

gunicorn --workers 3 --bind unix:/run/mysite.sock mysite.wsgi:application

```

```sh
ab -n 10000 -c 10000 http://127.0.0.1:8000/contents/?format=json&page_size=20
```