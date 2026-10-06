from django.http import Http404
from rest_framework.exceptions import NotFound
from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    """DRF's handler, with every 404 reduced to the same generic body.

    get_object_or_404 raises Http404 with "No <Model> matches the given query." for an
    unknown id but a bare Http404 for a non-numeric one; mapping both to NotFound()
    gives {"detail": "Not found."} in either case.
    """
    if isinstance(exc, Http404):
        exc = NotFound()
    return exception_handler(exc, context)
