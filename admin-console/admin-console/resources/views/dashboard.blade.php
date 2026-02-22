<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Admin Overview Dashboard') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow border-l-4 border-blue-500">
                    <div class="text-sm text-gray-500 uppercase font-bold">Active Alerts</div>
                    <div class="text-3xl font-bold text-gray-800">{{ $activeCount }}</div>
                </div>
                <div class="bg-white p-6 rounded-lg shadow border-l-4 border-green-500">
                    <div class="text-sm text-gray-500 uppercase font-bold">Resolved Total</div>
                    <div class="text-3xl font-bold text-gray-800">{{ $resolvedCount }}</div>
                </div>
                <div class="bg-white p-6 rounded-lg shadow border-l-4 border-red-500">
                    <div class="text-sm text-gray-500 uppercase font-bold">High Severity (Live)</div>
                    <div class="text-3xl font-bold text-gray-800">{{ $highSeverity }}</div>
                </div>
            </div>

            </div>
    </div>
</x-app-layout>
