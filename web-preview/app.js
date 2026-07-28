// ─── Firebase Config (cheers-hotel-bf5ce) ───
const firebaseConfig = {
  apiKey: "AIzaSyDDyKRMo6KbbrZwPg6YpVC-qCLp0iV5LEc",
  authDomain: "cheers-hotel-bf5ce.firebaseapp.com",
  projectId: "cheers-hotel-bf5ce",
  storageBucket: "cheers-hotel-bf5ce.firebasestorage.app",
  messagingSenderId: "574024389328",
  appId: "1:574024389328:web:b490d142f28881143204d5",
  measurementId: "G-224H95L4EN"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();
const auth = firebase.auth();
const RESTAURANT_ID = 'cheers-hotel-main';

// Enable offline persistence
db.enablePersistence({ synchronizeTabs: true }).catch(err => {
  console.warn('Offline persistence notice:', err.code);
});

// Firestore References
const menuRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('menuItems');
const ordersRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('orders');
const expensesRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('expenses');

// Clean, Deduplicated Menu Dataset from Cheers Hotel Stock Sheets
const DEDUPLICATED_STOCK_MENU = [
  // Favorites / Popular Essentials
  { name: 'EGGS', price: 70, category: 'Breakfast', popular: true },
  { name: 'CHAPATI', price: 20, category: 'Breakfast', popular: true },
  { name: 'CHAI NDOGO', price: 30, category: 'Breakfast', popular: true },
  { name: 'CHAI KUBWA', price: 50, category: 'Breakfast', popular: true },
  { name: 'MANDAZI', price: 10, category: 'Breakfast', popular: true },

  // Mains
  { name: 'UGALI MLIMA', price: 150, category: 'Mains' },
  { name: 'NYAMA STEW', price: 120, category: 'Mains' },
  { name: 'NYAMA FRY', price: 150, category: 'Mains' },
  { name: 'KUKU FRY', price: 320, category: 'Mains' },
  { name: 'KUKU STEW', price: 300, category: 'Mains' },
  { name: 'MAINI', price: 180, category: 'Mains' },
  { name: 'MATUMBO FRY', price: 120, category: 'Mains' },
  { name: 'MATUMBO STEW', price: 100, category: 'Mains' },
  { name: 'MBUZI', price: 150, category: 'Mains' },
  { name: 'PILAU', price: 100, category: 'Mains' },
  { name: 'WHITE RICE', price: 80, category: 'Mains' },
  { name: 'SAMAKI', price: 300, category: 'Mains' },
  { name: 'MADONDO', price: 50, category: 'Mains' },
  { name: 'NDENGU', price: 50, category: 'Mains' },
  { name: 'NDIZI/GITHERI', price: 50, category: 'Mains' },
  { name: 'SET', price: 120, category: 'Mains' },
  { name: 'BROILER', price: 200, category: 'Mains' },
  { name: 'CHIPS', price: 120, category: 'Mains' },

  // Snacks
  { name: 'SAMOSA', price: 30, category: 'Snacks', popular: true },
  { name: 'SAUSAGE', price: 50, category: 'Snacks', popular: true },
  { name: 'SMOKIES', price: 25, category: 'Snacks' },
  { name: 'CAKE', price: 100, category: 'Snacks' },

  // Drinks
  { name: 'SODA 300ML', price: 50, category: 'Drinks' },
  { name: 'SODA 500ML', price: 70, category: 'Drinks' },
  { name: 'DASANI 500ML', price: 40, category: 'Drinks' },
  { name: 'DASANI 1LTR', price: 70, category: 'Drinks' },
  { name: 'PET SODA', price: 50, category: 'Drinks' },
  { name: 'POWER PLAY', price: 50, category: 'Drinks' },
  { name: 'MINUTE MAID 300ML', price: 85, category: 'Drinks' }
];

// App State
let cart = {};              // { itemId: qty }
let menuItems = {};         // { id: {...} }
let activeCategory = '⭐ Favorites';
let searchQuery = '';
let paymentMethod = 'cash';
let currentPeriod = 'today';
let activeStaff = localStorage.getItem('cheers_staff') || 'Cathy';
let adminPin = localStorage.getItem('cheers_admin_pin') || '1234';
let isAdminUnlocked = false;
let pendingTargetTab = null;

// ─── Initialization ───
document.addEventListener('DOMContentLoaded', async () => {
  updateClock();
  setInterval(updateClock, 1000);

  // Restore active staff selector
  const staffSelect = document.getElementById('activeStaff');
  if (staffSelect) staffSelect.value = activeStaff;
  updateStaffDisplay();

  try {
    await auth.signInAnonymously();
    console.log('Auth OK');
  } catch (e) {
    console.warn('Auth notice:', e.message);
  }

  // Network online/offline monitor
  window.addEventListener('online', updateNetworkStatus);
  window.addEventListener('offline', updateNetworkStatus);
  updateNetworkStatus();

  // Listeners
  watchMenu();
  loadDashboard();
  watchKitchenOrders();

  // Default date filter for transactions
  const dateInput = document.getElementById('txnDateFilter');
  if (dateInput) dateInput.value = new Date().toISOString().split('T')[0];
});

function updateClock() {
  const now = new Date();
  const timeStr = now.toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' });
  const clockEl = document.getElementById('clock');
  if (clockEl) clockEl.textContent = timeStr;
}

function updateNetworkStatus() {
  const statusEl = document.getElementById('connectionStatus');
  if (!statusEl) return;
  if (navigator.onLine) {
    statusEl.innerHTML = '<span class="status-dot online"></span><span>Online Syncing</span>';
  } else {
    statusEl.innerHTML = '<span class="status-dot offline"></span><span>Offline Mode</span>';
  }
}

// ─── Staff Selection ───
function onStaffChange(staffName) {
  activeStaff = staffName;
  localStorage.setItem('cheers_staff', staffName);
  updateStaffDisplay();
  showToast(`👤 Staff changed to: ${staffName}`);
}

function updateStaffDisplay() {
  const badge = document.getElementById('activeStaffBadge');
  if (badge) badge.textContent = `Staff: ${activeStaff}`;
  const cartLabel = document.getElementById('cartStaffLabel');
  if (cartLabel) cartLabel.textContent = `By: ${activeStaff}`;
  const dashStaff = document.getElementById('dashStaffName');
  if (dashStaff) dashStaff.textContent = activeStaff;
}

// ─── Admin PIN Protection ───
function requestAdminAuth(targetTab) {
  if (isAdminUnlocked) {
    switchTab(targetTab);
    return;
  }
  pendingTargetTab = targetTab;
  document.getElementById('adminPinInput').value = '';
  document.getElementById('adminAuthModal').classList.add('show');
}

function verifyAdminPin() {
  const inputPin = document.getElementById('adminPinInput').value;
  if (inputPin === adminPin) {
    isAdminUnlocked = true;
    closeModal('adminAuthModal');
    showToast('🔓 Admin access granted!');
    if (pendingTargetTab) switchTab(pendingTargetTab);
  } else {
    showToast('❌ Incorrect PIN. Default is 1234.');
  }
}

// ─── Navigation ───
function switchTab(tab) {
  // If requesting analytics without admin lock
  if (tab === 'analytics' && !isAdminUnlocked) {
    requestAdminAuth('analytics');
    return;
  }

  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));

  const targetTabEl = document.getElementById('tab-' + tab);
  if (targetTabEl) targetTabEl.classList.add('active');

  const navBtn = document.querySelector(`[data-tab="${tab}"]`);
  if (navBtn) navBtn.classList.add('active');

  const titles = {
    dashboard: 'Dashboard Overview',
    order: 'New Order',
    kitchen: 'Kitchen Display System',
    transactions: 'Transactions History',
    menu: 'Menu Management',
    analytics: 'Sales Analytics & Reports 🔒',
    expenses: 'Daily Expenses',
    settings: 'System & Hardware Settings'
  };
  document.getElementById('pageTitle').textContent = titles[tab] || tab;

  if (tab === 'dashboard') loadDashboard();
  if (tab === 'analytics') loadReports();
  if (tab === 'transactions') loadTransactions();
  if (tab === 'expenses') loadExpenses();
  if (tab === 'menu') renderMenuList();
}

// ─── Menu Management & Real-time Watch ───
function watchMenu() {
  menuRef.onSnapshot(snap => {
    menuItems = {};
    snap.forEach(doc => {
      menuItems[doc.id] = { id: doc.id, ...doc.data() };
    });

    if (snap.empty) {
      autoSeedMenu();
    } else {
      renderCategoryFilter();
      renderMenuGrid();
      renderMenuList();
    }
  }, err => {
    console.error('Menu watch error:', err);
    showToast('⚠️ Firestore error: ' + err.message);
  });
}

async function autoSeedMenu() {
  showToast('⏳ Populating deduplicated menu...');
  const batch = db.batch();
  DEDUPLICATED_STOCK_MENU.forEach(item => {
    const docRef = menuRef.doc();
    batch.set(docRef, { ...item, active: true, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();
  showToast('✅ Menu initialized with stock dataset!');
}

async function seedMenu() {
  if (confirm('Reset menu database with the clean deduplicated stock dataset?')) {
    const snap = await menuRef.get();
    const batch = db.batch();
    snap.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    await autoSeedMenu();
  }
}

async function cleanAndDeduplicateMenu() {
  showToast('⏳ Cleaning duplicate items...');
  const snap = await menuRef.get();
  const seenNames = new Set();
  const batch = db.batch();
  let deletedCount = 0;

  snap.forEach(doc => {
    const name = (doc.data().name || '').trim().toUpperCase();
    if (seenNames.has(name)) {
      batch.delete(doc.ref);
      deletedCount++;
    } else {
      seenNames.add(name);
    }
  });

  if (deletedCount > 0) {
    await batch.commit();
    showToast(`✨ Removed ${deletedCount} duplicate menu items!`);
  } else {
    showToast('👍 Menu is already clean (no duplicates)!');
  }
}

// ─── Search & Category Filters ───
function renderCategoryFilter() {
  const container = document.getElementById('categoryFilter');
  if (!container) return;

  const categories = ['⭐ Favorites', 'All', 'Mains', 'Breakfast', 'Snacks', 'Drinks'];
  container.innerHTML = categories.map(cat => `
    <button class="cat-chip ${cat === activeCategory ? 'active' : ''}" onclick="setCategory('${cat}')">
      ${cat}
    </button>
  `).join('');
}

function setCategory(cat) {
  activeCategory = cat;
  renderCategoryFilter();
  renderMenuGrid();
}

function onSearchInput(val) {
  searchQuery = val.trim().toLowerCase();
  const clearBtn = document.getElementById('clearSearchBtn');
  if (clearBtn) clearBtn.style.display = searchQuery.length > 0 ? 'inline-block' : 'none';
  renderMenuGrid();
}

function clearSearch() {
  document.getElementById('menuSearchInput').value = '';
  searchQuery = '';
  document.getElementById('clearSearchBtn').style.display = 'none';
  renderMenuGrid();
}

// ─── Order Grid & Cart ───
function renderMenuGrid() {
  const grid = document.getElementById('menuGrid');
  if (!grid) return;

  const items = Object.values(menuItems).filter(item => {
    // Search query filter
    if (searchQuery) {
      return item.name.toLowerCase().includes(searchQuery) || (item.category || '').toLowerCase().includes(searchQuery);
    }
    // Category filter
    if (activeCategory === '⭐ Favorites') return item.popular === true;
    if (activeCategory === 'All') return true;
    return (item.category || 'Mains') === activeCategory;
  });

  if (items.length === 0) {
    grid.innerHTML = '<div class="empty-state"><p>No items found for this selection.</p></div>';
    return;
  }

  grid.innerHTML = items.map(item => {
    const qty = cart[item.id] || 0;
    const isOut = item.active === false;
    return `
      <div class="menu-card ${qty > 0 ? 'in-cart' : ''} ${isOut ? 'out-of-stock' : ''}" onclick="${isOut ? '' : `addToCart('${item.id}')`}">
        ${qty > 0 ? `<div class="qty-badge">${qty}</div>` : ''}
        <div class="item-category">${item.category || 'Mains'}</div>
        <div class="item-name">${item.name}</div>
        <div class="item-price">${isOut ? '<span class="out-tag">OUT OF STOCK</span>' : `KES ${Number(item.price).toLocaleString()}`}</div>
      </div>
    `;
  }).join('');
}

function addToCart(itemId) {
  cart[itemId] = (cart[itemId] || 0) + 1;
  updateCart();
}

function removeFromCart(itemId) {
  if (cart[itemId] > 1) {
    cart[itemId]--;
  } else {
    delete cart[itemId];
  }
  updateCart();
}

function deleteFromCart(itemId) {
  delete cart[itemId];
  updateCart();
}

function updateCart() {
  renderMenuGrid();
  const container = document.getElementById('cartItems');
  const recordBtn = document.getElementById('btnRecord');
  const countBadge = document.getElementById('cartCountLabel');
  const navBadge = document.getElementById('navCartBadge');

  const entries = Object.entries(cart);
  const totalCount = entries.reduce((sum, [, qty]) => sum + qty, 0);

  if (countBadge) countBadge.textContent = totalCount;
  if (navBadge) {
    navBadge.textContent = totalCount;
    navBadge.style.display = totalCount > 0 ? 'inline-block' : 'none';
  }

  if (entries.length === 0) {
    container.innerHTML = `
      <div class="cart-empty-msg">
        <span class="cart-empty-icon">🛒</span>
        <p>No items in cart</p>
        <small>Tap items on the left to add</small>
      </div>`;
    document.getElementById('cartTotal').textContent = 'KES 0';
    if (recordBtn) recordBtn.disabled = true;
    return;
  }

  if (recordBtn) recordBtn.disabled = false;

  let total = 0;
  const itemsHtml = entries.map(([id, qty]) => {
    const item = menuItems[id];
    if (!item) return '';
    const lineTotal = item.price * qty;
    total += lineTotal;
    return `
      <div class="cart-item">
        <div class="cart-item-info">
          <div class="cart-item-name">${item.name}</div>
          <div class="cart-item-price">KES ${Number(item.price).toLocaleString()} × ${qty} = <strong>KES ${lineTotal.toLocaleString()}</strong></div>
        </div>
        <div class="cart-item-controls">
          <button onclick="removeFromCart('${id}')" title="Decrease">−</button>
          <span class="cart-item-qty">${qty}</span>
          <button onclick="addToCart('${id}')" title="Increase">+</button>
          <button class="cart-delete-btn" onclick="deleteFromCart('${id}')" title="Remove">✕</button>
        </div>
      </div>
    `;
  }).join('');

  container.innerHTML = itemsHtml;
  document.getElementById('cartTotal').textContent = `KES ${total.toLocaleString()}`;
}

function setPayment(method) {
  paymentMethod = method;
  document.querySelectorAll('.pay-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.method === method);
  });
}

// ─── Order Checkout & Confirmation ───
function confirmOrder() {
  if (Object.keys(cart).length === 0) return;

  let total = 0;
  let html = '';
  Object.entries(cart).forEach(([id, qty]) => {
    const item = menuItems[id];
    if (!item) return;
    const lt = item.price * qty;
    total += lt;
    html += `
      <div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #e5e7eb;">
        <span><strong>${qty}x</strong> ${item.name}</span>
        <span>KES ${lt.toLocaleString()}</span>
      </div>`;
  });

  const sourceSelect = document.getElementById('settingSource');
  const source = sourceSelect ? sourceSelect.value : 'desktop';

  document.getElementById('confirmItems').innerHTML = html;
  document.getElementById('confirmTotal').innerHTML = `<span>TOTAL AMOUNT</span><span>KES ${total.toLocaleString()}</span>`;
  document.getElementById('confirmPayment').innerHTML = `
    <span>Staff: <strong>${activeStaff}</strong></span> • 
    <span>Payment: <strong>${paymentMethod === 'mpesa' ? '📱 M-Pesa' : '💵 Cash'}</strong></span> • 
    <span>Source: <strong>${source.toUpperCase()}</strong></span>
  `;
  document.getElementById('confirmModal').classList.add('show');
}

async function recordSale() {
  const btn = document.querySelector('#confirmModal .btn-primary');
  btn.disabled = true;
  btn.textContent = 'Processing & Printing...';

  try {
    const items = Object.entries(cart).map(([id, qty]) => {
      const item = menuItems[id];
      return { itemId: id, name: item.name, price: item.price, qty: qty, category: item.category || 'Mains' };
    });
    const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
    const sourceSelect = document.getElementById('settingSource');
    const source = sourceSelect ? sourceSelect.value : 'desktop';

    orderCounter++;
    const orderNum = String(orderCounter).padStart(3, '0');
    const now = new Date();
    const dateStr = now.toLocaleDateString('en-KE') + ' ' + now.toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' });

    const docRef = await ordersRef.add({
      orderNumber: orderNum,
      items: items,
      total: total,
      timestamp: firebase.firestore.FieldValue.serverTimestamp(),
      recordedBy: activeStaff,
      source: source,
      paymentMethod: paymentMethod,
      synced: true,
      receiptPrinted: true,
      kitchenStatus: 'pending'
    });

    // Populate Printable Thermal Receipt
    populatePrintableReceipt(orderNum, dateStr, activeStaff, items, total, paymentMethod);

    cart = {};
    updateCart();
    closeModal('confirmModal');
    showToast(`✅ Order #${orderNum} Recorded by ${activeStaff}! Total: KES ${total.toLocaleString()}`);
    
    // Trigger browser print dialog for thermal receipt printer
    setTimeout(() => {
      window.print();
    }, 400);

    loadDashboard();
  } catch (e) {
    console.error('Record sale error:', e);
    showToast('❌ Failed to record sale: ' + e.message);
  } finally {
    btn.disabled = false;
    btn.textContent = '✓ Confirm & Print';
  }
}

function populatePrintableReceipt(orderNum, dateStr, staff, items, total, payment) {
  document.getElementById('receiptOrderNum').textContent = `ORDER #${orderNum}`;
  document.getElementById('receiptDateTime').textContent = `Date: ${dateStr}`;
  document.getElementById('receiptStaff').textContent = `Staff: ${staff}`;
  
  const footerInput = document.getElementById('settingFooter');
  const footerText = footerInput ? footerInput.value : 'Thank you for dining with us! Cheers Hotel Nairobi';
  document.getElementById('receiptFooterMsg').innerHTML = footerText.replace('\n', '<br>');

  const itemsContainer = document.getElementById('receiptItemsBody');
  itemsContainer.innerHTML = items.map(i => {
    const lineTotal = i.price * i.qty;
    return `
      <div class="receipt-item-row">
        <span>${i.qty}x ${i.name}</span>
        <span>KES ${lineTotal.toLocaleString()}</span>
      </div>`;
  }).join('');

  document.getElementById('receiptTotalLine').textContent = `TOTAL: KES ${total.toLocaleString()}`;
  document.getElementById('receiptPaymentType').textContent = `PAID VIA ${payment.toUpperCase()}`;
}

async function printReceiptReprint(orderId) {
  try {
    const doc = await ordersRef.doc(orderId).get();
    if (!doc.exists) return;
    const o = doc.data();
    const orderNum = o.orderNumber || orderId.substring(0, 5).toUpperCase();
    const timeStr = o.timestamp?.toDate ? o.timestamp.toDate().toLocaleString('en-KE') : new Date().toLocaleString('en-KE');

    populatePrintableReceipt(orderNum, timeStr, o.recordedBy || 'Staff', o.items || [], o.total || 0, o.paymentMethod || 'cash');
    showToast(`🧾 Printing receipt for Order #${orderNum}...`);
    setTimeout(() => window.print(), 300);
  } catch (e) {
    showToast('❌ Error re-printing receipt');
  }
}

// ─── Dashboard Overview ───
async function loadDashboard() {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const end = new Date(start); end.setDate(end.getDate() + 1);

  try {
    const snap = await ordersRef
      .where('timestamp', '>=', start)
      .where('timestamp', '<', end)
      .get();

    let totalSales = 0;
    const popularMap = {};
    const orders = [];

    snap.forEach(doc => {
      const d = doc.data();
      totalSales += d.total || 0;
      (d.items || []).forEach(item => {
        popularMap[item.name] = (popularMap[item.name] || 0) + item.qty;
      });
      orders.push({ id: doc.id, ...d });
    });

    orders.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));

    // Stats Grid
    const statsContainer = document.getElementById('dashStatsGrid');
    if (statsContainer) {
      statsContainer.innerHTML = `
        <div class="stat-card"><div class="stat-label">Today's Total Sales</div><div class="stat-value sales">KES ${totalSales.toLocaleString()}</div></div>
        <div class="stat-card"><div class="stat-label">Orders Count</div><div class="stat-value">${snap.size}</div></div>
        <div class="stat-card"><div class="stat-label">Active Staff</div><div class="stat-value">${activeStaff}</div></div>
        <div class="stat-card"><div class="stat-label">System Status</div><div class="stat-value" style="color:#10b981;font-size:18px;">● Online</div></div>
      `;
    }

    const salesPill = document.getElementById('quickSalesPill');
    if (salesPill) salesPill.textContent = `Today: KES ${totalSales.toLocaleString()}`;

    // Popular Items
    const popContainer = document.getElementById('dashPopularItems');
    if (popContainer) {
      const sorted = Object.entries(popularMap).sort((a, b) => b[1] - a[1]).slice(0, 5);
      popContainer.innerHTML = sorted.length > 0
        ? sorted.map(([name, qty], i) => `
            <div class="top-item">
              <div class="top-item-info"><span class="top-item-rank">${i + 1}</span><span>${name}</span></div>
              <strong>${qty} sold</strong>
            </div>`).join('')
        : '<p style="color:#6b7280;padding:12px;">No sales recorded yet today.</p>';
    }

    // Recent Live Orders Stream
    const recentContainer = document.getElementById('dashRecentOrders');
    if (recentContainer) {
      recentContainer.innerHTML = orders.length > 0
        ? orders.slice(0, 6).map(o => {
            const time = o.timestamp?.toDate ? o.timestamp.toDate().toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' }) : 'Just now';
            const itemsSummary = (o.items || []).map(i => `${i.qty}x ${i.name}`).join(', ');
            return `
              <div class="order-row">
                <div class="order-main-info">
                  <span class="order-time">${time}</span>
                  <span class="order-staff-tag">👤 ${o.recordedBy || 'Staff'}</span>
                  <span class="order-payment-badge">${o.paymentMethod === 'mpesa' ? 'M-Pesa' : 'Cash'}</span>
                  <span class="order-items-summary">${itemsSummary}</span>
                </div>
                <span class="order-amount">KES ${(o.total || 0).toLocaleString()}</span>
              </div>`;
          }).join('')
        : '<p style="color:#6b7280;padding:12px;">No live orders recorded yet today.</p>';
    }

  } catch (e) {
    console.error('Dashboard error:', e);
  }
}

// ─── Kitchen Display System (KDS) ───
function watchKitchenOrders() {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  ordersRef
    .where('timestamp', '>=', start)
    .onSnapshot(snap => {
      const grid = document.getElementById('kdsGrid');
      const badge = document.getElementById('kitchenBadge');
      if (!grid) return;

      const activeOrders = [];
      snap.forEach(doc => {
        const d = { id: doc.id, ...doc.data() };
        if (d.kitchenStatus !== 'completed') {
          activeOrders.push(d);
        }
      });

      activeOrders.sort((a, b) => (a.timestamp?.seconds || 0) - (b.timestamp?.seconds || 0));
      if (badge) badge.textContent = activeOrders.length;

      if (activeOrders.length === 0) {
        grid.innerHTML = '<div class="empty-kds">🍳 Kitchen Queue Clear! All orders prepared.</div>';
        return;
      }

      grid.innerHTML = activeOrders.map((o, idx) => {
        const time = o.timestamp?.toDate ? o.timestamp.toDate().toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' }) : '';
        const status = o.kitchenStatus || 'pending';
        return `
          <div class="kds-card ${status}">
            <div class="kds-card-header">
              <span class="kds-order-num">Order #${idx + 1}</span>
              <span class="kds-time">${time}</span>
            </div>
            <div class="kds-staff">Server: <strong>${o.recordedBy || 'Staff'}</strong></div>
            <div class="kds-items">
              ${(o.items || []).map(i => `<div class="kds-item"><strong>${i.qty}x</strong> ${i.name}</div>`).join('')}
            </div>
            <div class="kds-actions">
              ${status === 'pending' ? `<button class="kds-btn prep" onclick="updateKitchenStatus('${o.id}', 'preparing')">🍳 Start Prep</button>` : ''}
              ${status === 'preparing' ? `<button class="kds-btn ready" onclick="updateKitchenStatus('${o.id}', 'completed')">✅ Mark Complete</button>` : ''}
            </div>
          </div>
        `;
      }).join('');
    });
}

async function updateKitchenStatus(orderId, newStatus) {
  try {
    await ordersRef.doc(orderId).update({ kitchenStatus: newStatus });
    showToast(`🍳 Kitchen status updated!`);
  } catch (e) {
    showToast('❌ Error updating kitchen: ' + e.message);
  }
}

// ─── Transactions Tab ───
async function loadTransactions() {
  const dateVal = document.getElementById('txnDateFilter').value;
  const staffVal = document.getElementById('txnStaffFilter').value;

  if (!dateVal) return;

  const start = new Date(dateVal);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);

  try {
    const snap = await ordersRef
      .where('timestamp', '>=', start)
      .where('timestamp', '<', end)
      .get();

    let totalRev = 0;
    let totalOrders = 0;
    let html = '';

    snap.forEach(doc => {
      const o = doc.data();
      if (staffVal !== 'ALL' && o.recordedBy !== staffVal) return;

      totalRev += o.total || 0;
      totalOrders++;
      const time = o.timestamp?.toDate ? o.timestamp.toDate().toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' }) : '';
      const itemsSummary = (o.items || []).map(i => `${i.qty}x ${i.name}`).join(', ');

      html += `
        <tr>
          <td><strong>${time}</strong><br><small style="color:#6b7280;">#${doc.id.substring(0,6)}</small></td>
          <td><span class="order-staff-tag">👤 ${o.recordedBy || 'Staff'}</span></td>
          <td><div style="max-width:260px;font-size:13px;">${itemsSummary}</div></td>
          <td><span class="order-payment-badge">${o.paymentMethod === 'mpesa' ? 'M-Pesa' : 'Cash'}</span></td>
          <td><span class="order-source ${o.source || 'desktop'}">${o.source || 'desktop'}</span></td>
          <td><strong>KES ${(o.total || 0).toLocaleString()}</strong></td>
          <td><button class="btn-secondary" style="padding:4px 8px;font-size:12px;" onclick="printReceiptReprint('${doc.id}')">🧾 Receipt</button></td>
        </tr>
      `;
    });

    document.getElementById('txnSummary').innerHTML = `
      <div class="stat-card"><div class="stat-label">Total Volume</div><div class="stat-value sales">KES ${totalRev.toLocaleString()}</div></div>
      <div class="stat-card"><div class="stat-label">Total Transactions</div><div class="stat-value">${totalOrders}</div></div>
    `;

    document.getElementById('txnTableBody').innerHTML = html || '<tr><td colspan="7" style="text-align:center;padding:24px;color:#6b7280;">No transactions found for this date/staff.</td></tr>';
  } catch (e) {
    console.error('Txn error:', e);
  }
}

function printReceiptReprint(orderId) {
  showToast(`🧾 Re-printing receipt for #${orderId.substring(0,6)}...`);
}

// ─── Menu Management Tab ───
function renderMenuList() {
  const list = document.getElementById('menuList');
  if (!list) return;

  menuRef.orderBy('category').get().then(snap => {
    let html = '';
    snap.forEach(doc => {
      const item = { id: doc.id, ...doc.data() };
      const active = item.active !== false;
      html += `
        <div class="menu-list-item">
          <div class="item-info">
            <h4>${item.name} ${item.popular ? '⭐' : ''}</h4>
            <span>${item.category || 'Mains'}</span>
          </div>
          <div class="item-actions">
            <span class="item-price-tag">KES ${Number(item.price).toLocaleString()}</span>
            <button class="btn-secondary" style="padding:6px 12px;font-size:12px;" onclick="openEditItemModal('${item.id}')">✏️ Edit</button>
            <button class="toggle-btn ${active ? 'active' : 'inactive'}" onclick="toggleMenuItem('${item.id}', ${!active})">
              ${active ? 'In Stock' : 'Out of Stock'}
            </button>
          </div>
        </div>
      `;
    });
    if (!html) html = '<p style="color:#6b7280;padding:20px;">No menu items. Click "+ Add Item" or "Reset Menu".</p>';
    list.innerHTML = html;
  });
}

function openEditItemModal(id) {
  const item = menuItems[id];
  if (!item) return;
  document.getElementById('editItemId').value = id;
  document.getElementById('editItemName').value = item.name;
  document.getElementById('editItemPrice').value = item.price;
  document.getElementById('editItemCategory').value = item.category || 'Mains';
  document.getElementById('editItemAvailable').checked = item.active !== false;
  document.getElementById('editItemModal').classList.add('show');
}

async function saveEditedMenuItem() {
  const id = document.getElementById('editItemId').value;
  const name = document.getElementById('editItemName').value.trim();
  const price = parseFloat(document.getElementById('editItemPrice').value);
  const category = document.getElementById('editItemCategory').value;
  const active = document.getElementById('editItemAvailable').checked;

  if (!name || isNaN(price)) {
    showToast('⚠️ Valid name and price required');
    return;
  }

  try {
    await menuRef.doc(id).update({ name, price, category, active });
    closeModal('editItemModal');
    showToast(`✅ "${name}" updated successfully!`);
    renderMenuList();
  } catch (e) {
    showToast('❌ Update error: ' + e.message);
  }
}

function showAddItemModal() { document.getElementById('addItemModal').classList.add('show'); }
function showAddExpenseModal() { document.getElementById('addExpenseModal').classList.add('show'); }
function closeModal(id) { document.getElementById(id).classList.remove('show'); }

async function addMenuItem() {
  const name = document.getElementById('itemName').value.trim();
  const price = parseFloat(document.getElementById('itemPrice').value);
  const category = document.getElementById('itemCategory').value;

  if (!name || isNaN(price)) {
    showToast('⚠️ Please enter name and price');
    return;
  }

  try {
    await menuRef.add({ name, price, category, active: true, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
    document.getElementById('itemName').value = '';
    document.getElementById('itemPrice').value = '';
    closeModal('addItemModal');
    showToast(`✅ "${name}" added to menu!`);
  } catch (e) {
    showToast('❌ Failed: ' + e.message);
  }
}

async function toggleMenuItem(id, newState) {
  try {
    await menuRef.doc(id).update({ active: newState });
    renderMenuList();
    showToast(newState ? '✅ Item marked In Stock' : '⏸️ Item marked Out of Stock');
  } catch (e) {
    showToast('❌ Failed: ' + e.message);
  }
}

// ─── Analytics & Graph Rendering ───
function setPeriod(period, btn) {
  currentPeriod = period;
  document.querySelectorAll('.period-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  loadReports();
}

async function loadReports() {
  const now = new Date();
  let start, end;

  switch (currentPeriod) {
    case 'today':
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      end = new Date(start); end.setDate(end.getDate() + 1);
      break;
    case 'week':
      start = new Date(now);
      start.setDate(now.getDate() - now.getDay() + 1);
      start.setHours(0, 0, 0, 0);
      end = new Date(start); end.setDate(end.getDate() + 7);
      break;
    case 'month':
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
      break;
  }

  try {
    const snap = await ordersRef
      .where('timestamp', '>=', start)
      .where('timestamp', '<', end)
      .get();

    let totalSales = 0;
    const topItems = {};
    const staffSales = {};
    const categorySales = {};
    const orders = [];

    snap.forEach(doc => {
      const data = doc.data();
      const orderTotal = data.total || 0;
      totalSales += orderTotal;

      const staff = data.recordedBy || 'Cathy';
      staffSales[staff] = (staffSales[staff] || 0) + orderTotal;

      (data.items || []).forEach(item => {
        topItems[item.name] = (topItems[item.name] || 0) + (item.qty || 1);
        const cat = item.category || 'Mains';
        categorySales[cat] = (categorySales[cat] || 0) + (item.price * item.qty);
      });
      orders.push({ id: doc.id, ...data });
    });

    // Render Stats
    const statsContainer = document.getElementById('statsGrid');
    if (statsContainer) {
      statsContainer.innerHTML = `
        <div class="stat-card"><div class="stat-label">Total Revenue</div><div class="stat-value sales">KES ${totalSales.toLocaleString()}</div></div>
        <div class="stat-card"><div class="stat-label">Total Orders</div><div class="stat-value">${snap.size}</div></div>
        <div class="stat-card"><div class="stat-label">Avg Order Value</div><div class="stat-value">KES ${snap.size > 0 ? Math.round(totalSales / snap.size).toLocaleString() : 0}</div></div>
      `;
    }

    // Render SVG Sales Trend Chart
    renderSalesTrendGraph(orders);

    // Top Selling Items
    const topContainer = document.getElementById('topItems');
    if (topContainer) {
      const sorted = Object.entries(topItems).sort((a, b) => b[1] - a[1]).slice(0, 5);
      topContainer.innerHTML = sorted.length > 0
        ? sorted.map(([name, qty], i) => `
            <div class="top-item">
              <div class="top-item-info"><span class="top-item-rank">${i + 1}</span><span>${name}</span></div>
              <strong>${qty} sold</strong>
            </div>`).join('')
        : '<p style="color:#6b7280;padding:12px;">No sales recorded yet.</p>';
    }

    // Staff Sales Breakdown
    const staffContainer = document.getElementById('staffSalesBreakdown');
    if (staffContainer) {
      const staffEntries = Object.entries(staffSales).sort((a, b) => b[1] - a[1]);
      staffContainer.innerHTML = staffEntries.length > 0
        ? staffEntries.map(([staff, rev]) => `
            <div class="top-item">
              <div class="top-item-info"><span class="top-item-rank">👤</span><span>${staff}</span></div>
              <strong>KES ${rev.toLocaleString()}</strong>
            </div>`).join('')
        : '<p style="color:#6b7280;padding:12px;">No staff reconciliation data.</p>';
    }

    // Category Breakdown
    const catContainer = document.getElementById('categoryBreakdown');
    if (catContainer) {
      const catEntries = Object.entries(categorySales).sort((a, b) => b[1] - a[1]);
      catContainer.innerHTML = catEntries.length > 0
        ? catEntries.map(([cat, amt]) => {
            const pct = totalSales > 0 ? Math.round((amt / totalSales) * 100) : 0;
            return `
              <div class="category-bar-row">
                <div class="cat-bar-header"><span>${cat}</span><strong>KES ${amt.toLocaleString()} (${pct}%)</strong></div>
                <div class="cat-bar-bg"><div class="cat-bar-fill" style="width:${pct}%;"></div></div>
              </div>`;
          }).join('')
        : '<p style="color:#6b7280;padding:12px;">No category sales data yet.</p>';
    }

  } catch (e) {
    console.error('Analytics error:', e);
  }
}

function renderSalesTrendGraph(orders) {
  const container = document.getElementById('salesTrendChart');
  if (!container) return;

  // Group by hour
  const hourlyData = Array(24).fill(0);
  orders.forEach(o => {
    if (o.timestamp?.toDate) {
      const hour = o.timestamp.toDate().getHours();
      hourlyData[hour] += o.total || 0;
    }
  });

  const maxVal = Math.max(...hourlyData, 1000);
  const chartHeight = 160;

  const barsSvg = hourlyData.map((val, h) => {
    const barH = (val / maxVal) * (chartHeight - 30);
    const x = h * 24 + 10;
    const y = chartHeight - barH - 20;
    return `
      <rect x="${x}" y="${y}" width="16" height="${barH}" rx="4" fill="${val > 0 ? '#8B1E2B' : '#e5e7eb'}" />
      ${h % 3 === 0 ? `<text x="${x + 8}" y="${chartHeight - 4}" font-size="10" text-anchor="middle" fill="#6b7280">${h}h</text>` : ''}
    `;
  }).join('');

  container.innerHTML = `
    <svg width="100%" height="${chartHeight}" viewBox="0 0 600 ${chartHeight}">
      ${barsSvg}
    </svg>
  `;
}

// ─── Expenses Tab ───
async function loadExpenses() {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const end = new Date(start); end.setDate(end.getDate() + 1);

  try {
    const snap = await expensesRef
      .where('date', '>=', start)
      .where('date', '<', end)
      .get();

    let totalExpenses = 0;
    let html = '';

    snap.forEach(doc => {
      const data = doc.data();
      totalExpenses += data.amount || 0;
      const time = data.date?.toDate ? data.date.toDate().toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' }) : '';
      html += `
        <div class="expense-item">
          <div class="expense-info">
            <h4>${data.description || 'Expense'}</h4>
            <span><strong>${data.category || 'Other'}</strong> • ${time}</span>
          </div>
          <span class="expense-amount">- KES ${(data.amount || 0).toLocaleString()}</span>
        </div>`;
    });

    document.getElementById('expensesSummary').innerHTML = `
      <div class="stat-card"><div class="stat-label">Today's Expenses Total</div><div class="stat-value" style="color:#ef4444">KES ${totalExpenses.toLocaleString()}</div></div>
      <div class="stat-card"><div class="stat-label">Entries Recorded</div><div class="stat-value">${snap.size}</div></div>
    `;
    document.getElementById('expensesList').innerHTML = html || '<p style="color:#6b7280;padding:20px;">No expenses recorded today.</p>';
  } catch (e) {
    console.error('Expenses error:', e);
  }
}

async function addExpense() {
  const desc = document.getElementById('expenseDesc').value.trim();
  const amount = parseFloat(document.getElementById('expenseAmount').value);
  const category = document.getElementById('expenseCategory').value;

  if (!desc || isNaN(amount)) {
    showToast('⚠️ Please enter description and amount');
    return;
  }

  try {
    await expensesRef.add({
      description: desc,
      amount: amount,
      category: category,
      date: firebase.firestore.FieldValue.serverTimestamp(),
      recordedBy: activeStaff
    });
    document.getElementById('expenseDesc').value = '';
    document.getElementById('expenseAmount').value = '';
    closeModal('addExpenseModal');
    loadExpenses();
    showToast(`✅ Expense saved: KES ${amount.toLocaleString()} (${category})`);
  } catch (e) {
    showToast('❌ Failed: ' + e.message);
  }
}

// ─── Settings Admin Configuration ───
function saveAdminSettings() {
  const name = document.getElementById('settingRestName').value;
  const newPin = document.getElementById('settingAdminPin').value;
  if (newPin) {
    adminPin = newPin;
    localStorage.setItem('cheers_admin_pin', newPin);
  }
  showToast(`✅ Saved admin configuration for ${name}!`);
}

async function clearAllOrders() {
  if (confirm('Clear all orders? This action cannot be undone.')) {
    const snap = await ordersRef.get();
    const batch = db.batch();
    snap.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    showToast('🧹 All orders cleared!');
    loadDashboard();
  }
}

// ─── Toast Notifications ───
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3200);
}

// Modal overlay close handler
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) overlay.classList.remove('show');
  });
});
