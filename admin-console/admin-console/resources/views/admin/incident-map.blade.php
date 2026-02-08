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

    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

    <script>
        // 1. Initialise the map centered on Penang
        var map = L.map('map').setView([5.4164, 100.3301], 12);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        // 2. Click to Alert Logic
        var marker, circle;

        map.on('click', function(e){
            if (marker) map.removeLayer(marker);
            if (circle) map.removeLayer(circle);

            marker = L.marker(e.latlng).addTo(map);
            circle = L.circle(e.latlng,{
                color: 'red',
                radius: 1000
            }).addTo(map);

            // This verifies "Admin Command" is capturing data correctly
            console.log("Admin Map Clicked at: " + e.latlng.lat + ", " + e.latlng.lng);
        });
    </script>
</x-app-layout>