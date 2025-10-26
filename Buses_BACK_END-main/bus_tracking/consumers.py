# bus_tracking/consumers.py

import json
from channels.generic.websocket import WebsocketConsumer
from asgiref.sync import async_to_sync

class BusLocationConsumer(WebsocketConsumer):
    """
    WebSocket consumer for real-time bus location updates.
    Clients can connect to receive live updates on bus locations.
    """

    def connect(self):
        print("WebSocket connecting...")
        self.accept()
        print("WebSocket accepted")
        # Join the 'bus_locations' group to receive broadcasts
        async_to_sync(self.channel_layer.group_add)('bus_locations', self.channel_name)
        print("Joined group")

    def disconnect(self, close_code):
        print("WebSocket disconnecting...")
        # Leave the group
        async_to_sync(self.channel_layer.group_discard)('bus_locations', self.channel_name)
        print("Left group")

    # Handle incoming messages from WebSocket (optional, for future features like subscribing to specific buses)
    def receive(self, text_data):
        # For now, just acknowledge
        self.send(text_data=json.dumps({'message': 'Received', 'data': json.loads(text_data)}))

    # Method called when a bus location update is broadcasted
    def bus_location_update(self, event):
        # Send the update to the WebSocket
        self.send(text_data=json.dumps(event['data']))