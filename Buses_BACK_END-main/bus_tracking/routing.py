# bus_tracking/routing.py

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/bus-locations/?$', consumers.BusLocationConsumer.as_asgi()),
]