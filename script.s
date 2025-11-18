// === 1. KONFIGURASI DAN INISIALISASI ===

// Kunci untuk localStorage
const STORAGE_KEYS = {
    INVENTORY: 'rentalyuk_inventory',
    RENTALS: 'rentalyuk_rentals',
    HISTORY: 'rentalyuk_history',
    PROFILE: 'rentalyuk_profile'
};

// (BARU) Struktur harga default (berbasis map/objek)
const DEFAULT_PRICING_MAP = {
    "30": 0, "60": 0, "90": 0, "120": 0, "180": 0, "300": 0, "720": 0, "1440": 0
};

// === 2. DATA STATE LOKAL (CACHE) ===
let localInventory = [];
let localRentals = [];
let localHistory = [];
let localProfile = {};

let confirmCallback = null; 
let countdownTimerInterval = null;
let selectedSettingsPicDataUrl = null; 
let selectedSetupPicDataUrl = null;    

let statsChart = null;
const statsChartCanvas = document.getElementById('stats-pie-chart');
const statsNoData = document.getElementById('stats-no-data');

// === 4. SELEKTOR DOM ===
const navLinks = document.querySelectorAll('.nav-link');
const pages = {
    dashboard: document.getElementById('page-dashboard'),
    inventory: document.getElementById('page-inventory'),
    laporan: document.getElementById('page-laporan'),
    settings: document.getElementById('page-settings'),
    stats: document.getElementById('page-stats')
};
const mainContent = document.getElementById('main-content');

// Selektor Setup
const setupModal = document.getElementById('setup-modal');
const setupForm = document.getElementById('setup-form');
const setupRentalName = document.getElementById('setup-rental-name');
const setupProfileUpload = document.getElementById('setup-profile-upload');
const setupProfilePreview = document.getElementById('setup-profile-preview');

// Selektor Profil & Pengaturan
const sidebarProfilePic = document.getElementById('sidebar-profile-pic');
const dashboardGreeting = document.getElementById('dashboard-greeting');
const rentalNameForm = document.getElementById('rental-name-form');
const settingsRentalName = document.getElementById('settings-rental-name');
const settingsProfilePreview = document.getElementById('settings-profile-preview');
const profilePicUpload = document.getElementById('profile-pic-upload');
const saveProfileBtn = document.getElementById('save-profile-btn');
const deleteAllDataBtn = document.getElementById('delete-all-data-btn');

// (DIUBAH) Selektor Modal Harga Item
const pricingModal = document.getElementById('pricing-modal');
const pricingForm = document.getElementById('pricing-form');
const pricingItemId = document.getElementById('pricing-item-id');
const pricingItemName = document.getElementById('pricing-item-name');
const pricingCancelBtn = document.getElementById('pricing-cancel-btn');

// Selektor Inventaris
const inventoryTableBody = document.getElementById('inventory-table-body');
const inventoryModal = document.getElementById('inventory-modal');
const addInventoryBtn = document.getElementById('add-inventory-btn');
const inventoryForm = document.getElementById('inventory-form');
const inventoryCancelBtn = document.getElementById('inventory-cancel-btn');
const seedDataBtn = document.getElementById('seed-data-btn');

// Selektor Stok
const stockModal = document.getElementById('stock-modal');
const stockForm = document.getElementById('stock-form');
const stockItemId = document.getElementById('stock-item-id');
const stockItemName = document.getElementById('stock-item-name');
const stockAmount = document.getElementById('stock-amount');
const stockCancelBtn = document.getElementById('stock-cancel-btn');
const stockReduceBtn = document.getElementById('stock-reduce-btn');
const stockAddBtn = document.getElementById('stock-add-btn');

// Selektor Sewa & Laporan
const rentalsTableBody = document.getElementById('rentals-table-body');
const historyTableBody = document.getElementById('history-table-body');
const laporanTableBody = document.getElementById('laporan-table-body');
const rentalModal = document.getElementById('rental-modal');
const addRentalBtn = document.getElementById('addRentalBtn');
const cancelBtn = document.getElementById('cancelBtn');
const rentalForm = document.getElementById('rental-form');
const rentalPriceDisplay = document.getElementById('rental-price-display'); 

// Selektor Dropdown Kustom
const itemSelectInput = document.getElementById('item-select');
const itemSelectTrigger = document.getElementById('item-select-trigger');
const itemSelectText = document.getElementById('item-select-text');
const itemSelectOptions = document.getElementById('item-select-options');

const durationSelectInput = document.getElementById('rental-duration');
const durationPriceInput = document.getElementById('rental-price'); 
const durationSelectTrigger = document.getElementById('rental-duration-trigger');
const durationSelectText = document.getElementById('rental-duration-text');
const durationSelectOptions = document.getElementById('rental-duration-options');

// Selektor Statistik Dashboard
const statTotalRevenue = document.getElementById('stat-total-revenue'); 
const statTotal = document.getElementById('stat-total-items');
const statOnRent = document.getElementById('stat-on-rent');
const statAvailable = document.getElementById('stat-available');

// Selektor Modal Pesan
const messageModal = document.getElementById('message-modal');
const messageText = document.getElementById('message-text');
const messageOkBtn = document.getElementById('message-ok-btn');
const messageCancelBtn = document.getElementById('message-cancel-btn');

// === FUNGSI HELPER LOCALSTORAGE ===

function loadFromStorage(key, defaultValue = []) {
    try {
        const item = localStorage.getItem(key);
        return item ? JSON.parse(item) : defaultValue;
    } catch (e) {
        console.error(`Gagal memuat ${key} dari localStorage`, e);
        return defaultValue;
    }
}

function saveToStorage(key, data) {
    try {
        localStorage.setItem(key, JSON.stringify(data));
    } catch (e) {
        console.error(`Gagal menyimpan ${key} ke localStorage`, e);
        showMessage("Error: Gagal menyimpan data. Penyimpanan mungkin penuh.");
    }
}

// === 5. FUNGSI-FUNGSI RENDER (UI) ===

function showMessage(message) {
    console.log("Menampilkan Pesan:", message);
    messageText.textContent = message;
    messageOkBtn.textContent = "OK";
    messageOkBtn.classList.remove('hidden');
    messageCancelBtn.classList.add('hidden');
    openModal(messageModal);
    confirmCallback = null; 
}

function showConfirm(message, onConfirm) {
    console.log("Menampilkan Konfirmasi:", message);
    messageText.textContent = message;
    messageOkBtn.textContent = "Ya, Lanjutkan";
    messageOkBtn.classList.remove('hidden');
    messageCancelBtn.classList.remove('hidden');
    openModal(messageModal);
    confirmCallback = onConfirm;
}

function renderAllUI() {
    renderInventoryTable();
    renderRentals();
    renderLaporan();
    renderHistory();
    updateStats();
    if (pages.stats.classList.contains('hidden') === false) {
        renderStatsPage();
    }
}

function renderInventoryTable() { 
    if (!inventoryTableBody) return; 
    inventoryTableBody.innerHTML = ''; 
    if (localInventory.length === 0) {
        inventoryTableBody.innerHTML = `<tr><td colspan="5" class="px-4 py-3 text-center text-gray-500">Inventaris kosong.</td></tr>`;
        seedDataBtn.classList.remove('hidden');
        return;
    }
    seedDataBtn.classList.add('hidden');
    const sortedInventory = [...localInventory].sort((a, b) => a.name.localeCompare(b.name));
    sortedInventory.forEach(item => {
        const availableStock = item.totalStock - item.rentedStock;
        const availableClass = availableStock > 0 ? 'text-green-400' : 'text-gray-500';
         const deleteClass = item.rentedStock > 0 
            ? 'opacity-50 cursor-not-allowed' 
            : 'text-red-500 hover:text-red-700';
        
        const row = `
            <tr>
                <td class="px-4 py-3 whitespace-nowrap"><div class="text-sm font-medium text-gray-100">${item.name}</div></td>
                <td class="px-4 py-3 whitespace-nowrap">
                    <span class="h-4 w-4 rounded-full inline-block border border-gray-600" style="background-color: ${item.color || '#888'}"></span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm font-bold ${availableClass}">${availableStock}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-300">${item.totalStock}</td>
                <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium space-x-2">
                    <button data-id="${item.id}" class="edit-price-btn text-yellow-400 hover:text-yellow-600 transition-colors text-xs">Harga</button>
                    <button data-id="${item.id}" class="edit-stock-btn text-blue-400 hover:text-blue-600 transition-colors text-xs">Stok</button>
                    <button data-id="${item.id}" class="delete-item-btn ${deleteClass} text-xs" ${item.rentedStock > 0 ? 'disabled' : ''}>Hapus</button>
                </td>
            </tr>`;
        inventoryTableBody.innerHTML += row; 
    });
}

function renderRentals() {
    if (!rentalsTableBody) return; 
    rentalsTableBody.innerHTML = ''; 
    if (localRentals.length === 0) {
        rentalsTableBody.innerHTML = `<tr><td colspan="4" class="px-6 py-4 text-center text-gray-500">Tidak ada data sewa aktif.</td></tr>`;
        return;
    }
    const sortedRentals = [...localRentals].sort((a, b) => a.startTime.localeCompare(b.startTime));
    sortedRentals.forEach(rental => {
        const item = localInventory.find(inv => inv.id === rental.itemId);
        const itemName = item ? item.name : 'Barang Dihapus';
        const row = `
            <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-100">${itemName}</div>
                    <div class="text-xs text-gray-400">ID: ${rental.itemId}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-300">${rental.renterName}</td>
                <td classid="countdown-cell" class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-yellow-400" 
                    data-start-time="${rental.startTime}" data-duration-minutes="${rental.durationMinutes}">
                    Menghitung...
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button data-rental-id="${rental.id}" data-item-id="${rental.itemId}" class="text-red-500 hover:text-red-700 font-semibold transition-colors return-btn">
                        Akhiri Sesi
                    </button>
                </td>
            </tr>`;
        rentalsTableBody.innerHTML += row;
    });
    updateAllCountdowns();
}

function renderLaporan() {
    if (!laporanTableBody) return; 
    laporanTableBody.innerHTML = ''; 
    if (localRentals.length === 0) {
        laporanTableBody.innerHTML = `<tr><td colspan="5" class="px-6 py-4 text-center text-gray-500">Tidak ada sewa yang sedang aktif.</td></tr>`;
        return;
    }
    const sortedRentals = [...localRentals].sort((a, b) => a.startTime.localeCompare(b.startTime));
    sortedRentals.forEach(rental => {
        const item = localInventory.find(inv => inv.id === rental.itemId);
        const itemName = item ? item.name : 'Barang Dihapus';
        const priceText = `Rp ${(rental.price || 0).toLocaleString('id-ID')}`;
        
        const row = `
            <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="flex items-center">
                        <span class="h-3 w-3 bg-green-500 rounded-full inline-block mr-2 animate-pulse"></span>
                        <span class="text-sm font-medium text-green-400">Online</span>
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-300">${rental.renterName}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-100">${itemName}</div>
                    <div class="text-xs text-gray-400">ID: ${rental.itemId}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-green-400">${priceText}</td>
                <td classid="countdown-cell" class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-yellow-400" 
                    data-start-time="${rental.startTime}" data-duration-minutes="${rental.durationMinutes}">
                    Menghitung...
                </td>
            </tr>`;
        laporanTableBody.innerHTML += row;
    });
    updateAllCountdowns();
}

function renderHistory() {
    if (!historyTableBody) return; 
    historyTableBody.innerHTML = '';
    if (localHistory.length === 0) {
        historyTableBody.innerHTML = `<tr><td colspan="5" class="px-4 py-3 text-center text-gray-500">Belum ada histori.</td></tr>`;
        return;
    }
    const reversedHistory = [...localHistory].sort((a, b) => b.returnDate.localeCompare(a.returnDate));
    reversedHistory.forEach(entry => {
        const item = localInventory.find(inv => inv.id === entry.itemId);
        const itemName = item ? item.name : 'Barang Dihapus';
        const durationText = formatDuration(entry.durationMinutes);
        const priceText = `Rp ${(entry.price || 0).toLocaleString('id-ID')}`;

        const row = `
            <tr>
                <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-100">${itemName}</div>
                    <div class="text-xs text-gray-400">ID: ${entry.itemId}</div>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-300">${entry.renterName}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-300">${durationText}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-green-400">${priceText}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                    <span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-800 text-green-200">
                        ${entry.status}
                    </span>
                </td>
            </tr>`;
        historyTableBody.innerHTML += row;
    });
}

function updateStats() {
    const totalItems = localInventory.reduce((sum, item) => sum + item.totalStock, 0);
    const onRentItems = localInventory.reduce((sum, item) => sum + item.rentedStock, 0);
    const availableItems = totalItems - onRentItems;
    const totalRevenue = localHistory.reduce((sum, entry) => sum + (entry.price || 0), 0);
    
    if (statTotalRevenue) statTotalRevenue.textContent = `Rp ${totalRevenue.toLocaleString('id-ID')}`;
    if (statTotal) statTotal.textContent = totalItems;
    if (statOnRent) statOnRent.textContent = onRentItems;
    if (statAvailable) statAvailable.textContent = availableItems;
}

function populateItemSelect() {
    if (!itemSelectOptions) return; 
    console.log("Memperbarui dropdown item (kustom)...");
    itemSelectOptions.innerHTML = '';
    
    itemSelectText.textContent = "Pilih barang...";
    itemSelectText.classList.add('text-gray-400');
    itemSelectInput.value = "";
    
    durationSelectText.textContent = "Pilih barang dulu...";
    durationSelectText.classList.add('text-gray-400');
    durationSelectInput.value = "";
    durationPriceInput.value = "";
    durationSelectTrigger.disabled = true;
    
    const availableItems = localInventory.filter(item => (item.totalStock - item.rentedStock) > 0);
    
    if (availableItems.length === 0) {
        itemSelectOptions.innerHTML = '<li class="dropdown-option text-gray-400 cursor-not-allowed">Tidak ada item yang tersedia</li>';
        return;
    }
    
    availableItems.forEach(item => {
        const availableStock = item.totalStock - item.rentedStock;
        const li = document.createElement('li');
        li.className = 'dropdown-option';
        li.textContent = `${item.name} (Stok: ${availableStock})`;
        li.dataset.value = item.id;
        itemSelectOptions.appendChild(li);
    });
}

function populateDurationDropdown(itemId) {
    const item = localInventory.find(i => i.id === itemId);
    durationSelectOptions.innerHTML = '';
    
    durationSelectText.textContent = "Pilih durasi...";
    durationSelectText.classList.add('text-gray-400');
    durationSelectInput.value = "";
    durationPriceInput.value = "";
    updateRentalPriceDisplay();
    
    if (!item || !item.pricing) {
        durationSelectOptions.innerHTML = '<li class="dropdown-option text-gray-400 cursor-not-allowed">Tidak ada paket harga</li>';
        durationSelectTrigger.disabled = true;
        return;
    }
    
    const availablePackages = [];
    for (const [duration, price] of Object.entries(item.pricing)) {
        if (price > 0) {
            availablePackages.push({ duration: parseInt(duration), price: price });
        }
    }
    
    if (availablePackages.length === 0) {
         durationSelectOptions.innerHTML = '<li class="dropdown-option text-gray-400 cursor-not-allowed">Harga belum diatur</li>';
         durationSelectTrigger.disabled = true;
         return;
    }
    
    durationSelectTrigger.disabled = false;
    
    const sortedPricing = availablePackages.sort((a, b) => a.duration - b.duration);
    
    sortedPricing.forEach(pkg => {
        const li = document.createElement('li');
        li.className = 'dropdown-option';
        li.textContent = `${formatDuration(pkg.duration)} (Rp ${pkg.price.toLocaleString('id-ID')})`;
        li.dataset.value = pkg.duration;
        li.dataset.price = pkg.price; 
        durationSelectOptions.appendChild(li);
    });
}

function updateRentalPriceDisplay() {
    const price = parseInt(durationPriceInput.value) || 0; 
    rentalPriceDisplay.textContent = `Harga: Rp ${price.toLocaleString('id-ID')}`;
}

// === 6. FUNGSI-FUNGSI LOGIKA (Interaksi & localStorage) ===

function formatDuration(totalMinutes) {
    if (isNaN(totalMinutes) || totalMinutes < 0) return "Durasi Invalid";
    if (totalMinutes === 0) return "0 Menit";
    
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    
    let parts = [];
    if (hours > 0) {
        parts.push(`${hours} Jam`);
    }
    if (minutes > 0) {
        parts.push(`${minutes} Menit`);
    }
    
    return parts.join(' ');
}

function formatTime(ms) {
    let seconds = Math.floor(ms / 1000);
    let minutes = Math.floor(seconds / 60);
    let hours = Math.floor(minutes / 60);
    seconds = seconds % 60;
    minutes = minutes % 60;
    const pad = (num) => num.toString().padStart(2, '0');
    return `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
}

function updateAllCountdowns() {
    const countdownCells = document.querySelectorAll('[classid="countdown-cell"]');
    const now = new Date();
    countdownCells.forEach(cell => {
        const startTimeStr = cell.dataset.startTime;
        const durationMinutes = parseInt(cell.dataset.durationMinutes, 10);
        if (!startTimeStr || isNaN(durationMinutes)) {
            cell.textContent = "Error Data";
            return;
        }
        const startTime = new Date(startTimeStr);
        const endTime = new Date(startTime.getTime() + durationMinutes * 60 * 1000);
        const remainingMs = endTime.getTime() - now.getTime();
        if (remainingMs <= 0) {
            cell.textContent = "Waktu Habis";
            cell.classList.remove('text-yellow-400');
            cell.classList.add('text-red-500');
        } else {
            cell.textContent = formatTime(remainingMs);
            cell.classList.add('text-yellow-400');
            cell.classList.remove('text-red-500');
        }
    });
}

function generateRandomHexColor() {
    return '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
}

function generateUniqueColor(existingColors = []) {
    let newColor;
    let attempts = 0;
    do {
        newColor = generateRandomHexColor();
        attempts++;
        if (attempts > 50) break;
    } while (existingColors.includes(newColor));
    return newColor;
}

function seedDatabase() {
    console.log("Mengecek data awal...");
    if (localInventory.length === 0) {
        console.log("Database kosong. Menambahkan data awal...");
        const existingColors = [];
        const mockInventory = [
            { id: 'PS1', name: 'PlayStation 1', category: 'Konsol', totalStock: 0, rentedStock: 0 },
            { id: 'PS2', name: 'PlayStation 2', category: 'Konsol', totalStock: 0, rentedStock: 0 },
            { id: 'PS3', name: 'PlayStation 3', category: 'Konsol', totalStock: 0, rentedStock: 0 },
            { id: 'PS4', name: 'PlayStation 4', category: 'Konsol', totalStock: 0, rentedStock: 0 },
            { id: 'PS5', name: 'PlayStation 5', category: 'Konsol', totalStock: 0, rentedStock: 0 },
        ];
        
        localInventory = mockInventory.map(item => {
            const color = generateUniqueColor(existingColors);
            existingColors.push(color);
            return {...item, color: color, pricing: { ...DEFAULT_PRICING_MAP } };
        });
        
        saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
        renderInventoryTable();
        showMessage("Data contoh berhasil ditambahkan dengan stok 0 dan paket harga default (Rp 0).");
    } else {
        showMessage("Database sudah berisi data.");
    }
}

function handleAddRental(e) {
    e.preventDefault();
    const formData = new FormData(rentalForm);
    const newItemId = formData.get('itemId'); 
    const newRenterName = formData.get('renterName');
    const newDurationMinutes = parseInt(formData.get('durationMinutes'), 10); 
    const newPrice = parseInt(durationPriceInput.value, 10); 
    
    if (!newItemId || !newRenterName || isNaN(newDurationMinutes)) {
        showMessage("Harap isi semua field.");
        return;
    }
    if (isNaN(newPrice) || newPrice <= 0) {
         showMessage("Error: Harga tidak valid. Pastikan harga paket > Rp 0.");
         return;
    }

    const itemInInventory = localInventory.find(item => item.id === newItemId);
    if (!itemInInventory) {
        showMessage("Error: Item tidak ditemukan.");
        return;
    }

    if (itemInInventory.totalStock - itemInInventory.rentedStock <= 0) {
        showMessage("Error: Stok item ini sudah habis.");
        return;
    }

    const newRental = {
        id: crypto.randomUUID(), 
        itemId: newItemId,
        renterName: newRenterName,
        startTime: new Date().toISOString(),
        durationMinutes: newDurationMinutes,
        price: newPrice 
    };

    localRentals.push(newRental);
    itemInInventory.rentedStock += 1;

    saveToStorage(STORAGE_KEYS.RENTALS, localRentals);
    saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
    
    console.log("Sewa baru berhasil ditambahkan");
    closeModal(rentalModal);
    rentalForm.reset();
    
    populateItemSelect(); 
    populateDurationDropdown(null); 
    
    renderAllUI();
}

function handleReturnRental(e) {
    const targetButton = e.target.closest('.return-btn');
    if (targetButton) {
        const rentalIdToReturn = targetButton.dataset.rentalId;
        const itemIdToReturn = targetButton.dataset.itemId;
        if (!rentalIdToReturn || !itemIdToReturn) {
            showMessage("Error: ID barang atau ID sewa tidak ditemukan.");
            return;
        }

        const rentalToMoveIndex = localRentals.findIndex(rental => rental.id === rentalIdToReturn);
        if (rentalToMoveIndex === -1) {
             showMessage("Error: Data sewa tidak ditemukan.");
             return;
        }
        
        const rentalToMove = localRentals[rentalToMoveIndex];

        const historyEntry = {
            id: crypto.randomUUID(), 
            itemId: rentalToMove.itemId,
            renterName: rentalToMove.renterName,
            returnDate: new Date().toISOString().split('T')[0],
            status: 'Selesai',
            durationMinutes: rentalToMove.durationMinutes,
            price: rentalToMove.price || 0 
        };

        const itemInInventory = localInventory.find(item => item.id === itemIdToReturn);

        localRentals.splice(rentalToMoveIndex, 1); 
        localHistory.push(historyEntry); 
        if (itemInInventory) {
            itemInInventory.rentedStock -= 1;
            if (itemInInventory.rentedStock < 0) itemInInventory.rentedStock = 0;
        }

        saveToStorage(STORAGE_KEYS.RENTALS, localRentals);
        saveToStorage(STORAGE_KEYS.HISTORY, localHistory);
        saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
        
        console.log("Barang berhasil dikembalikan");
        renderAllUI();
    }
}

function handleAddInventory(e) {
    e.preventDefault();
    const formData = new FormData(inventoryForm);
    const itemId = formData.get('itemId').toUpperCase().trim();
    const itemName = formData.get('itemName').trim();
    const itemCategory = formData.get('itemCategory').trim();
    const itemStock = parseInt(formData.get('itemStock'));
    if (!itemId || !itemName || !itemCategory || isNaN(itemStock)) {
        showMessage("Harap isi semua field dengan benar.");
        return;
    }
    if (itemStock <= 0) {
        showMessage("Stok awal harus lebih dari 0.");
        return;
    }
    
    const itemExists = localInventory.find(item => item.id === itemId);
    if (itemExists) {
        showMessage(`Error: Item dengan ID "${itemId}" sudah ada.`);
        return;
    }
    
    const existingColors = localInventory.map(i => i.color).filter(Boolean);
    const newItemColor = generateUniqueColor(existingColors);
    
    const newItem = {
        id: itemId, 
        name: itemName,
        category: itemCategory,
        totalStock: itemStock,
        rentedStock: 0,
        color: newItemColor,
        pricing: { ...DEFAULT_PRICING_MAP } 
    };
    
    localInventory.push(newItem);
    saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
    
    showMessage(`Item "${itemName}" berhasil ditambahkan.`);
    closeModal(inventoryModal);
    inventoryForm.reset();
    
    renderAllUI();
}

function handleManageInventoryClick(e) {
    const editBtn = e.target.closest('.edit-stock-btn');
    const deleteBtn = e.target.closest('.delete-item-btn');
    const priceBtn = e.target.closest('.edit-price-btn'); 
    
    if (priceBtn) { 
        const id = priceBtn.dataset.id;
        openPricingModal(id);
    }
    
    if (editBtn) {
        const id = editBtn.dataset.id;
        const item = localInventory.find(i => i.id === id);
        if (item) {
            stockItemId.value = id;
            stockItemName.textContent = item.name;
            stockAmount.value = 1;
            openModal(stockModal);
        }
    }
    if (deleteBtn) {
        const id = deleteBtn.dataset.id;
        const item = localInventory.find(i => i.id === id);
        if (item) {
            if (item.rentedStock > 0) {
                showMessage("Error: Tidak bisa menghapus item yang sedang disewa.");
                return;
            }
            showConfirm(`Anda yakin ingin menghapus "${item.name}"? Aksi ini tidak bisa dibatalkan.`, () => {
                deleteInventoryItem(id);
            });
        }
    }
}

function openPricingModal(id) {
    const item = localInventory.find(i => i.id === id);
    if (!item) {
        showMessage("Error: Item tidak ditemukan.");
        return;
    }
    
    pricingItemId.value = id;
    pricingItemName.textContent = item.name;
    
    if (!item.pricing) {
        item.pricing = { ...DEFAULT_PRICING_MAP };
    }
    
    const inputs = pricingModal.querySelectorAll('.price-input');
    inputs.forEach(input => {
        const minutes = input.dataset.minutes;
        input.value = item.pricing[minutes] || 0;
    });
    
    openModal(pricingModal);
}

function handleSaveItemPricing(e) {
    e.preventDefault();
    const id = pricingItemId.value;
    const item = localInventory.find(i => i.id === id);
    if (!item) {
        showMessage("Error: Item tidak ditemukan.");
        return;
    }
    
    const inputs = pricingForm.querySelectorAll('.price-input');
    
    if (!item.pricing) {
        item.pricing = { ...DEFAULT_PRICING_MAP };
    }
    
    inputs.forEach(input => {
        const minutes = input.dataset.minutes;
        const price = parseInt(input.value) || 0;
        item.pricing[minutes] = price;
    });
    
    saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
    showMessage(`Harga untuk "${item.name}" berhasil diperbarui.`);
    closeModal(pricingModal);
}

function deleteInventoryItem(id) {
    localInventory = localInventory.filter(item => item.id !== id);
    saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
    showMessage("Item berhasil dihapus.");
    renderAllUI();
}

function handleUpdateStock(action) {
    const id = stockItemId.value;
    const amount = parseInt(stockAmount.value);
    if (isNaN(amount) || amount <= 0) {
        showMessage("Jumlah harus angka positif.");
        return;
    }
    const item = localInventory.find(i => i.id === id);
    if (!item) {
        showMessage("Error: Item tidak ditemukan.");
        return;
    }

    if (action === 'add') {
        item.totalStock += amount;
        showMessage(`Stok "${item.name}" berhasil ditambah ${amount}.`);
    } else if (action === 'reduce') {
        const newTotalStock = item.totalStock - amount;
        if (newTotalStock < item.rentedStock) {
            showMessage(`Error: Stok total tidak bisa lebih kecil dari yang sedang disewa (${item.rentedStock}).`);
            return;
        }
        if (newTotalStock < 0) {
            showMessage("Error: Stok total tidak bisa negatif.");
            return;
        }
        item.totalStock = newTotalStock;
        showMessage(`Stok "${item.name}" berhasil dikurangi ${amount}.`);
    }

    saveToStorage(STORAGE_KEYS.INVENTORY, localInventory);
    closeModal(stockModal);
    renderAllUI();
}

function handleImageFile(file, imgElement, onLoaded) {
    if (!file) return;
    
    if (!['image/jpeg', 'image/png'].includes(file.type)) {
        showMessage("Error: Hanya file .jpg atau .png yang diizinkan.");
        return;
    }

    const maxSize = 2 * 1024 * 1024; // 2MB
    if (file.size > maxSize) {
        showMessage("Error: Ukuran file terlalu besar. Maksimal 2MB.");
        return;
    }
    
    const reader = new FileReader();
    reader.onload = (event) => {
        const dataUrl = event.target.result;
        imgElement.src = dataUrl;
        imgElement.classList.remove('rounded-full');
        imgElement.classList.add('rounded-lg');
        onLoaded(dataUrl); 
    };
    reader.readAsDataURL(file);
}

function handleSetupPicPreview(e) {
    handleImageFile(e.target.files[0], setupProfilePreview, (dataUrl) => {
        selectedSetupPicDataUrl = dataUrl;
    });
    e.target.value = ""; 
}

function handleSettingsPicPreview(e) {
    handleImageFile(e.target.files[0], settingsProfilePreview, (dataUrl) => {
        selectedSettingsPicDataUrl = dataUrl;
        saveProfileBtn.disabled = false;
        saveProfileBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    });
    e.target.value = ""; 
}

function updateProfileUI(profile) {
    const defaultPreview = "https://placehold.co/150x150/374151/E0E0E0?text=Profil";
    const rentalName = profile.rentalName || "Rental Anda";
    const photoURL = profile.photoURL;

    dashboardGreeting.textContent = `Selamat datang di ${rentalName}!`;
    settingsRentalName.value = rentalName;
    
    if (photoURL) {
        sidebarProfilePic.src = photoURL;
        sidebarProfilePic.classList.remove('hidden');
        settingsProfilePreview.src = photoURL;
        settingsProfilePreview.classList.remove('rounded-full');
        settingsProfilePreview.classList.add('rounded-lg');
    } else {
        sidebarProfilePic.classList.add('hidden');
        settingsProfilePreview.src = defaultPreview;
        settingsProfilePreview.classList.add('rounded-full');
        settingsProfilePreview.classList.remove('rounded-lg');
    }
}

function handleRentalNameSave(e) {
    e.preventDefault();
    const newName = settingsRentalName.value.trim();
    if (!newName) {
        showMessage("Nama rental tidak boleh kosong.");
        return;
    }
    
    localProfile.rentalName = newName;
    saveToStorage(STORAGE_KEYS.PROFILE, localProfile);
    updateProfileUI(localProfile);
    showMessage("Nama rental berhasil diperbarui.");
}

function handleProfilePicUpload() {
    if (!selectedSettingsPicDataUrl) {
        showMessage("Anda belum memilih gambar baru.");
        return;
    }

    saveProfileBtn.disabled = true;
    saveProfileBtn.textContent = "Menyimpan...";
    saveProfileBtn.classList.add('opacity-50', 'cursor-not-allowed');
    
    localProfile.photoURL = selectedSettingsPicDataUrl;
    saveToStorage(STORAGE_KEYS.PROFILE, localProfile);
    
    selectedSettingsPicDataUrl = null;
    showMessage("Gambar profil berhasil diperbarui!");
    updateProfileUI(localProfile);
    saveProfileBtn.textContent = "Simpan Perubahan Profil";
}

function handleSetupSubmit(e) {
    e.preventDefault();
    const rentalName = setupRentalName.value.trim();
    if (!rentalName) {
        showMessage("Nama Rental wajib diisi untuk melanjutkan.");
        return;
    }
    
    const setupButton = setupForm.querySelector('button[type="submit"]');
    setupButton.disabled = true;
    setupButton.textContent = "Menyimpan...";

    localProfile = {
        rentalName: rentalName,
        photoURL: selectedSetupPicDataUrl || null
    };
    
    saveToStorage(STORAGE_KEYS.PROFILE, localProfile);
    
    closeModal(setupModal);
    initializeMainApp();
}

function openModal(modalElement) {
    modalElement.classList.remove('hidden');
    modalElement.classList.add('flex');
    const modalContent = modalElement.querySelector('.modal-content-area');
    if (modalContent) {
        modalContent.classList.remove('modal-closing');
        modalContent.classList.add('modal-showing');
    }
}
function closeModal(modalElement) {
    const modalContent = modalElement.querySelector('.modal-content-area');
    if (modalContent) {
        modalContent.classList.remove('modal-showing');
        modalContent.classList.add('modal-closing');
        setTimeout(() => {
            modalElement.classList.add('hidden');
            modalElement.classList.remove('flex');
            modalContent.classList.remove('modal-closing');
        }, 300);
    } else {
        modalElement.classList.add('hidden');
        modalElement.classList.remove('flex');
    }
}

function navigateTo(pageId) {
    Object.values(pages).forEach(page => page.classList.add('hidden'));
    if (pages[pageId]) {
        pages[pageId].classList.remove('hidden');
    }
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.id === `nav-${pageId}`) {
            link.classList.add('active');
        }
    });
    updateAllCountdowns();
    
    if (pageId === 'stats') {
        renderStatsPage();
    }
}

function initChart() {
    if (statsChart) {
        statsChart.destroy();
    }
    Chart.defaults.color = '#D1D5DB';
    Chart.defaults.font.family = "'Inter', 'sans-serif'";
    const ctx = statsChartCanvas.getContext('2d');
    statsChart = new Chart(ctx, {
        type: 'pie',
        data: {
            labels: [],
            datasets: [{
                label: 'Total Jam Penggunaan',
                data: [],
                backgroundColor: [],
                borderColor: '#1f2937',
                borderWidth: 2,
                hoverOffset: 8
            }]
        },
        options: {
             responsive: true,
             maintainAspectRatio: true,
             plugins: {
                 legend: {
                     position: 'bottom',
                     labels: {
                         padding: 15,
                         boxWidth: 12,
                     }
                 },
                 tooltip: {
                     callbacks: {
                         label: function(context) {
                             let label = context.label || '';
                             let value = context.raw || 0;
                             if (label) {
                                 label += ': ';
                             }
                             label += `${value.toFixed(1)} Jam`;
                             return label;
                         }
                     }
                 }
             }
        }
    });
}
function renderStatsPage() {
    if (!statsChart) initChart();
    const itemUsage = {};
    localHistory.forEach(entry => {
        if (!entry.durationMinutes) return; 
        const hours = entry.durationMinutes / 60;
        const id = entry.itemId;
        if (!itemUsage[id]) { itemUsage[id] = 0; }
        itemUsage[id] += hours;
    });
    const labels = [];
    const data = [];
    const colors = [];
    Object.keys(itemUsage).forEach(itemId => {
        const item = localInventory.find(i => i.id === itemId);
        const itemName = item ? item.name : 'Item Dihapus';
        const itemColor = item ? item.color : '#888888';
        labels.push(itemName);
        data.push(itemUsage[itemId]);
        colors.push(itemColor);
    });
    if (data.length === 0) {
        statsChartCanvas.classList.add('hidden');
        statsNoData.classList.remove('hidden');
    } else {
        statsChartCanvas.classList.remove('hidden');
        statsNoData.classList.add('hidden');
    }
    statsChart.data.labels = labels;
    statsChart.data.datasets[0].data = data;
    statsChart.data.datasets[0].backgroundColor = colors;
    statsChart.update();
}

function handleDeleteAllData() {
    showConfirm("Anda YAKIN ingin menghapus SEMUA data? Ini akan menghapus inventaris, sewa, histori, dan profil Anda secara permanen.", () => {
        localStorage.removeItem(STORAGE_KEYS.INVENTORY);
        localStorage.removeItem(STORAGE_KEYS.RENTALS);
        localStorage.removeItem(STORAGE_KEYS.HISTORY);
        localStorage.removeItem(STORAGE_KEYS.PROFILE);
        location.reload();
    });
}

function initializeMainApp() {
    updateProfileUI(localProfile);
    renderAllUI();
    
    if (countdownTimerInterval) clearInterval(countdownTimerInterval);
    countdownTimerInterval = setInterval(updateAllCountdowns, 1000);

    // Listener Navigasi & Modal
    addRentalBtn.addEventListener('click', () => {
        populateItemSelect(); 
        populateDurationDropdown(null); 
        updateRentalPriceDisplay();
        openModal(rentalModal);
    });
    cancelBtn.addEventListener('click', () => closeModal(rentalModal));
    rentalModal.addEventListener('click', (e) => { if (e.target === rentalModal) closeModal(rentalModal); });
    addInventoryBtn.addEventListener('click', () => openModal(inventoryModal));
    inventoryCancelBtn.addEventListener('click', () => closeModal(inventoryModal));
    inventoryModal.addEventListener('click', (e) => { if (e.target === inventoryModal) closeModal(inventoryModal); });
    stockCancelBtn.addEventListener('click', () => closeModal(stockModal));
    stockModal.addEventListener('click', (e) => { if (e.target === stockModal) closeModal(stockModal); });
    messageOkBtn.addEventListener('click', () => {
        if (confirmCallback) {
            confirmCallback();
            confirmCallback = null;
        }
        closeModal(messageModal);
    });
    messageCancelBtn.addEventListener('click', () => {
        confirmCallback = null;
        closeModal(messageModal);
    });
    
    pricingCancelBtn.addEventListener('click', () => closeModal(pricingModal));
    pricingModal.addEventListener('click', (e) => { if (e.target === pricingModal) closeModal(pricingModal); });
    pricingForm.addEventListener('submit', handleSaveItemPricing); 
    
    // Listener Tombol Stok
    stockAddBtn.addEventListener('click', () => handleUpdateStock('add'));
    stockReduceBtn.addEventListener('click', () => handleUpdateStock('reduce'));
    
    // Listener Navigasi Halaman
    document.getElementById('nav-dashboard').addEventListener('click', (e) => { e.preventDefault(); navigateTo('dashboard'); });
    document.getElementById('nav-inventory').addEventListener('click', (e) => { e.preventDefault(); navigateTo('inventory'); });
    document.getElementById('nav-laporan').addEventListener('click', (e) => { e.preventDefault(); navigateTo('laporan'); });
    document.getElementById('nav-settings').addEventListener('click', (e) => { e.preventDefault(); navigateTo('settings'); });
    document.getElementById('nav-stats').addEventListener('click', (e) => { e.preventDefault(); navigateTo('stats'); });
    
    // Listener Form Submit
    rentalForm.addEventListener('submit', handleAddRental);
    inventoryForm.addEventListener('submit', handleAddInventory);
    rentalNameForm.addEventListener('submit', handleRentalNameSave);
    
    // Listener Lain-lain
    seedDataBtn.addEventListener('click', seedDatabase);
    profilePicUpload.addEventListener('change', handleSettingsPicPreview);
    saveProfileBtn.addEventListener('click', handleProfilePicUpload);
    deleteAllDataBtn.addEventListener('click', handleDeleteAllData);
    rentalsTableBody.addEventListener('click', handleReturnRental);
    inventoryTableBody.addEventListener('click', handleManageInventoryClick);

    // Listener untuk Dropdown Kustom
    function setupDropdown(triggerEl, optionsEl, inputEl, textEl, onSelectCallback = null) {
        triggerEl.addEventListener('click', (e) => {
            e.stopPropagation();
            const isOpen = optionsEl.classList.contains('open');
            closeAllDropdowns();
            if (!isOpen && !triggerEl.disabled) { 
                optionsEl.classList.add('open');
                triggerEl.classList.add('open');
            }
        });

        optionsEl.addEventListener('click', (e) => {
            const option = e.target.closest('.dropdown-option');
            if (option && option.dataset.value) {
                const selectedValue = option.dataset.value;
                const selectedText = option.textContent;
                
                inputEl.value = selectedValue;
                textEl.textContent = selectedText;
                textEl.classList.remove('text-gray-400');
                
                optionsEl.querySelectorAll('.dropdown-option').forEach(opt => opt.classList.remove('selected'));
                option.classList.add('selected');
                
                closeAllDropdowns();
                
                if (option.dataset.price) {
                    durationPriceInput.value = option.dataset.price;
                }
                
                if (onSelectCallback) {
                    onSelectCallback(selectedValue);
                }
            }
        });
    }
    
    function closeAllDropdowns() {
        document.querySelectorAll('.dropdown-panel.open').forEach(panel => panel.classList.remove('open'));
        document.querySelectorAll('.dropdown-trigger.open').forEach(trigger => trigger.classList.remove('open'));
    }

    setupDropdown(itemSelectTrigger, itemSelectOptions, itemSelectInput, itemSelectText, (itemId) => {
        populateDurationDropdown(itemId); 
    });
    setupDropdown(durationSelectTrigger, durationSelectOptions, durationSelectInput, durationSelectText, () => {
        updateRentalPriceDisplay(); 
    });

    window.addEventListener('click', () => {
        closeAllDropdowns();
    });

    initChart();
    navigateTo('dashboard');
}

// === 7. INISIALISASI APLIKASI ===

function main() {
    localInventory = loadFromStorage(STORAGE_KEYS.INVENTORY, []);
    localRentals = loadFromStorage(STORAGE_KEYS.RENTALS, []);
    localHistory = loadFromStorage(STORAGE_KEYS.HISTORY, []);
    localProfile = loadFromStorage(STORAGE_KEYS.PROFILE, {});

    if (!localProfile.rentalName) {
        console.log("User setup incomplete. Opening setup modal.");
        openModal(setupModal);
        setupForm.addEventListener('submit', handleSetupSubmit);
        setupProfileUpload.addEventListener('change', handleSetupPicPreview);
    } else {
        console.log("User already set up. Initializing app.");
        initializeMainApp();
    }
}

// Jalankan aplikasi
main();
