<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Manage Active Alerts') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-lg font-bold">Currently Active Incidents</h3>
                    <span class="bg-green-100 text-green-800 text-xs font-semibold px-2.5 py-0.5 rounded">
                        {{ $activeAlerts->count() }} Live Alerts
                    </span>
                </div>

                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Incident</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Severity</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location/Radius</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @forelse($activeAlerts as $alert)
                            <tr>
                                <td class="px-6 py-4">
                                    <div class="text-sm font-bold text-gray-900">{{ $alert->title }}</div>
                                    <div class="text-xs text-gray-500 truncate w-48">{{ $alert->instruction }}</div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="px-2 py-1 rounded-full text-white text-xs font-bold uppercase" 
                                          style="background-color: {{ 
                                          strtoupper($alert->severity) == 'HIGH' ? '#ef4444' : 
                                          (strtoupper($alert->severity) == 'MEDIUM' ? '#f59e0b' : '#facc15') 
                                          }}">
                                        {{ $alert->severity }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 text-sm text-gray-500">
                                    {{ round($alert->latitude, 4) }}, {{ round($alert->longitude, 4) }}
                                    <div class="text-xs italic">Radius: {{ $alert->radius }}m</div>
                                </td>
                                <td class="px-6 py-4 text-sm text-gray-500">
                                    {{ $alert->created_at->diffForHumans() }}
                                </td>
                                <td class="px-6 py-4 text-right">
                                    <button onclick="resolveAlert({{ $alert->alert_id }})" 
                                            class="inline-flex items-center px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-xs font-bold rounded transition">
                                        Mark Resolved
                                    </button>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="5" class="px-6 py-10 text-center text-gray-500 italic">
                                    No active alerts found.
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Axios logic to resolve alerts -->
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
    <script>
        function resolveAlert(id) {
            if (!confirm('Are you sure the incident is resolved? This will remove it from the public map.')) return;

            // Sends PATCH request
            axios.patch(`/api/alerts/${id}/resolve`)
                .then(response => {
                    alert(response.data.message);
                    window.location.reload(); // Refresh to update list
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Failed to resolve alert.');
                });
        }
    </script>
</x-app-layout>