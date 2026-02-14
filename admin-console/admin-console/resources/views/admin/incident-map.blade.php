<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Incident Command Centre') }}
        </h2>
    </x-slot>

    <div class="py-12" 
        x-data="{ open: false, lat: '', lng: '', radius: 1000 }"
        @open-modal.window="open = true; lat = $event.detail.lat; lng = $event.detail.lng">  <!-- Alpine.js Event Listener -->
            <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg p-6">
                    <div id="map" style="height: 600px; width: 100%; border-radius: 8px; z-index: 1;"></div>
                </div>
            </div>

            <!-- Broadcast Model Pop-Up for Alert Fill-in Form -->
            <div x-show="open" 
                class="fixed inset-0 z-[9999] overflow-y-auto" 
                style="display: none;"
                x-transition:enter="transition ease-out duration-300"
                x-transition:enter-start="opacity-0"
                x-transition:enter-end="opacity-100">
                
                <div class="flex items-center justify-center min-h-screen px-4">
                    <div class="fixed inset-0 bg-gray-500 opacity-75"></div>

                    <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full p-6 relative z-10">
                        <h3 class="text-lg font-medium text-gray-900 mb-4">Broadcast New Alert</h3>
                        
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-700">Alert Title</label>
                                <input type="text" id="modal_title" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-red-500 focus:border-red-500" placeholder="e.g., Road Accident">
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-gray-700">Instructions</label>
                                <textarea id="modal_instruction" rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-red-500 focus:border-red-500" placeholder="e.g., Use alternative routes..."></textarea>
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-gray-700">Severity Level</label>
                                <select id="modal_severity" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                                    <option value="Low">Low</option>
                                    <option value="Medium" selected>Medium</option>
                                    <option value="High">High</option>
                                    <option value="Critical">Critical</option>
                                </select>
                            </div>

                            <div class="text-xs text-gray-500 italic">
                                Target Coordinates: <span x-text="lat"></span>, <span x-text="lng"></span>
                            </div>
                        </div>

                        <div class="mt-6 flex justify-end space-x-3">
                            <button @click="open = false" type="button" class="bg-gray-200 px-4 py-2 rounded-md text-gray-700 hover:bg-gray-300">Cancel</button>
                            <button @click="sendAlert(lat, lng, radius); open = false" type="button" class="bg-red-600 px-4 py-2 rounded-md text-white hover:bg-red-700">Confirm & Broadcast</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    <!-- Leaflet Assets --> 
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

    <!-- Control Geocoder Assets --> 
    <link rel="stylesheet" href="https://unpkg.com/leaflet-control-geocoder/dist/Control.Geocoder.css" />
    <script src="https://unpkg.com/leaflet-control-geocoder/dist/Control.Geocoder.js"></script>

    <script>
        // 1. Initialise the map centered on Penang
        const lat = 5.4164;
        const lng = 100.3301;
        const zoomVal = 13; 

        var map = L.map('map').setView([lat, lng], zoomVal);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        // Initialise Search Bar 
        var geocoder = L.Control.geocoder({
            defaultMarkGeocode: false
        })
        .on('markgeocode', function(e) {
            var bbox = e.geocode.bbox;
            var poly = L.polygon([
            bbox.getSouthEast(),
            bbox.getNorthEast(),
            bbox.getNorthWest(),
            bbox.getSouthWest()
            ]);
            map.fitBounds(poly.getBounds()); // Zoom into the searched area
        })
        .addTo(map);

        // 2. Click to Alert Logic
        var marker, circle;

        map.on('click', function(e){
        // 1. Manage Map Visuals
        if (marker) map.removeLayer(marker);
        if (circle) map.removeLayer(circle);

        marker = L.marker(e.latlng).addTo(map);
        circle = L.circle(e.latlng, {
            color: 'red',
            radius: 1000 
        }).addTo(map);

        // 2. Open the Modal using the Event Dispatcher 
        window.dispatchEvent(new CustomEvent('open-modal', { 
            detail: { lat: e.latlng.lat, lng: e.latlng.lng } 
            }));
        });

        // Actual Broadcast Function
        function sendAlert(lat, lng, radius) {
            axios.post('/api/send-alert', {
                title: document.getElementById('modal_title').value,
                instruction: document.getElementById('modal_instruction').value,
                severity: document.getElementById('modal_severity').value,
                latitude: lat,
                longitude: lng,
                radius: radius
            })
            .then(response => {
                alert("Alert saved! ID: " + response.data.alert_id + " | Users notified: " + response.data.notified_count);
        
        // Clean up: Clear the inputs for the next click
        document.getElementById('modal_title').value = '';
        document.getElementById('modal_instruction').value = '';
        })
        .catch(error => {
            console.error("The alert could not be saved:", error);
        });
    }
           
    </script>
</x-app-layout>