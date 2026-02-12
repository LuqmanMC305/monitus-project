<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Incident Command Centre') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg p-6">
                <div id="map" style="height: 600px; width: 100%; border-radius: 8px;"></div>
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
            // Ensure the danger zone is visible
            if (marker) map.removeLayer(marker);
            if (circle) map.removeLayer(circle);

            marker = L.marker(e.latlng).addTo(map);
            circle = L.circle(e.latlng,{
                color: 'red',
                radius: 1000 // Must match this with the radius sent to the backend
            }).addTo(map);

            // Send the data to AlertController
            axios.post('/api/send-alert',{
                title: "Manual Emergency Trigger", // Hardcoded for now
                instruction: "Please stay away from the red zone.",
                latitude: e.latlng.lat,
                longitude: e.latlng.lng,
                radius: 1000,
                severity: "Medium"
            })
            .then(response => {
                // Show success notification in browser
                alert("Alert saved! ID: " + response.data.alert_id + " | Users notified: " + response.data.notified_count);
            })
            .catch(error => {
                console.error("The alert could not be saved:", error.response.data);
            });
        });
    </script>
</x-app-layout>