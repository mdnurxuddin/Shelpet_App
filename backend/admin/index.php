<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShelPet Admin Panel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Outfit', sans-serif; background-color: #0A0A0C; color: white; }
        .card { background-color: #16161A; border: 1px solid #2D2D33; }
        .accent-blue { color: #4FC3F7; }
        .bg-blue { background-color: #0056B3; }
        .tab-btn.active { border-bottom: 2px solid #4FC3F7; color: #4FC3F7; }
    </style>
</head>
<body class="p-8">
    <div class="max-w-6xl mx-auto">
        <header class="flex justify-between items-center mb-10">
            <div>
                <h1 class="text-3xl font-bold">ShelPet <span class="accent-blue">Admin Panel</span></h1>
                <p class="text-gray-400">Control Center for your Community</p>
            </div>
            <div class="bg-blue px-6 py-2 rounded-full font-bold">Logged as Admin</div>
        </header>

        <!-- Navigation Tabs -->
        <div class="flex space-x-8 mb-8 border-b border-gray-800">
            <button onclick="showTab('users')" id="tab-users" class="tab-btn pb-4 font-bold active">NID Verifications</button>
            <button onclick="showTab('orders')" id="tab-orders" class="tab-btn pb-4 font-bold text-gray-500">Store Orders</button>
            <button onclick="showTab('store')" id="tab-store" class="tab-btn pb-4 font-bold text-gray-500">Manage Products</button>
        </div>

        <!-- USERS TAB -->
        <div id="section-users" class="tab-section">
            <h2 class="text-xl font-bold mb-4">Pending Verifications</h2>
            <div class="card rounded-2xl overflow-hidden">
                <table class="w-full text-left">
                    <thead class="bg-[#1C1C22] text-gray-400 uppercase text-sm">
                        <tr>
                            <th class="p-4">User</th>
                            <th class="p-4">NID Number</th>
                            <th class="p-4">Image</th>
                            <th class="p-4">Action</th>
                        </tr>
                    </thead>
                    <tbody id="user-list"></tbody>
                </table>
            </div>
        </div>

        <!-- ORDERS TAB -->
        <div id="section-orders" class="tab-section hidden">
            <h2 class="text-xl font-bold mb-4">Customer Orders</h2>
            <div class="card rounded-2xl overflow-hidden">
                <table class="w-full text-left">
                    <thead class="bg-[#1C1C22] text-gray-400 uppercase text-sm">
                        <tr>
                            <th class="p-4">Order ID</th>
                            <th class="p-4">Product</th>
                            <th class="p-4">Customer</th>
                            <th class="p-4">Total</th>
                            <th class="p-4">Status</th>
                            <th class="p-4">Action</th>
                        </tr>
                    </thead>
                    <tbody id="order-list"></tbody>
                </table>
            </div>
        </div>

        <!-- STORE TAB (Coming soon integration) -->
        <div id="section-store" class="tab-section hidden">
            <h2 class="text-xl font-bold mb-4">Add New Store Product</h2>
            <div class="card p-6 rounded-2xl max-w-xl">
                <p class="text-gray-400 mb-6">Tip: You can add products directly from the mobile app as an Admin.</p>
                <div class="space-y-4">
                    <p class="text-sm text-blue-300">New products added here will be available to all users in the Pet Store.</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        function showTab(tab) {
            document.querySelectorAll('.tab-section').forEach(s => s.classList.add('hidden'));
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active', 'text-white'));
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.add('text-gray-500'));

            document.getElementById('section-' + tab).classList.remove('hidden');
            document.getElementById('tab-' + tab).classList.add('active', 'text-white');

            if(tab === 'users') loadUsers();
            if(tab === 'orders') loadOrders();
        }

        async function loadUsers() {
            const response = await fetch('get_pending_users.php');
            const result = await response.json();
            const list = document.getElementById('user-list');
            list.innerHTML = '';

            result.data.forEach(user => {
                list.innerHTML += `
                    <tr class="border-t border-[#2D2D33]">
                        <td class="p-4">
                            <div class="flex items-center">
                                <img src="${user.avatar ? user.avatar : 'https://i.pravatar.cc/100?u='+user.id}" class="h-10 w-10 rounded-full mr-3 object-cover">
                                <div><div class="font-bold">${user.name}</div><div class="text-xs text-gray-500">${user.email}</div></div>
                            </div>
                        </td>
                        <td class="p-4 font-mono font-bold">${user.nid_number}</td>
                        <td class="p-4">
                            <a href="${user.nid_front_image}" target="_blank">
                                <img src="${user.nid_front_image}" class="h-10 w-16 object-cover rounded border border-gray-700">
                            </a>
                        </td>
                        <td class="p-4">
                            <button onclick="updateUserStatus(${user.id}, 'verified')" class="bg-green-600 hover:bg-green-700 px-3 py-1 rounded text-xs font-bold mr-1">Approve</button>
                            <button onclick="updateUserStatus(${user.id}, 'rejected')" class="bg-red-600 hover:bg-red-700 px-3 py-1 rounded text-xs font-bold">Reject</button>
                        </td>
                    </tr>
                `;
            });
        }

        async function loadOrders() {
            const response = await fetch('get_all_orders.php');
            const result = await response.json();
            const list = document.getElementById('order-list');
            list.innerHTML = '';

            result.data.forEach(order => {
                list.innerHTML += `
                    <tr class="border-t border-[#2D2D33]">
                        <td class="p-4 text-gray-500">#ORD-${order.id}</td>
                        <td class="p-4 font-bold text-blue-300">${order.product_name}</td>
                        <td class="p-4">
                            <div class="font-bold">${order.buyer_name}</div>
                            <div class="text-xs text-gray-500">${order.phone_number}</div>
                            <div class="text-xs text-gray-400 italic">${order.shipping_address}</div>
                        </td>
                        <td class="p-4 font-bold">৳${order.total_price}</td>
                        <td class="p-4">
                            <span class="px-2 py-1 rounded text-[10px] font-bold uppercase ${getStatusColor(order.status)}">${order.status}</span>
                        </td>
                        <td class="p-4">
                            <select onchange="updateOrderStatus(${order.id}, this.value)" class="bg-[#1C1C22] border border-gray-700 rounded p-1 text-xs outline-none">
                                <option value="">Action</option>
                                <option value="accepted">Accept</option>
                                <option value="shipped">Ship</option>
                                <option value="delivered">Deliver</option>
                                <option value="cancelled">Cancel</option>
                            </select>
                        </td>
                    </tr>
                `;
            });
        }

        function getStatusColor(status) {
            if(status === 'pending') return 'bg-orange-900 text-orange-200';
            if(status === 'accepted') return 'bg-blue-900 text-blue-200';
            if(status === 'shipped') return 'bg-purple-900 text-purple-200';
            if(status === 'delivered') return 'bg-green-900 text-green-200';
            return 'bg-red-900 text-red-200';
        }

        async function updateUserStatus(userId, status) {
            await fetch('update_status.php', { method: 'POST', body: JSON.stringify({ user_id: userId, status: status }) });
            loadUsers();
        }

        async function updateOrderStatus(orderId, status) {
            if(!status) return;
            await fetch('../store/update_order_status.php', { method: 'POST', body: JSON.stringify({ order_id: orderId, status: status }) });
            loadOrders();
        }

        loadUsers();
    </script>
</body>
</html>
