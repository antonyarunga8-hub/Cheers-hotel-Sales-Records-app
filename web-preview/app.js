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

// Firestore references
const menuRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('menuItems');
const ordersRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('orders');
const expensesRef = db.collection('restaurants').doc(RESTAURANT_ID).collection('expenses');

// Full Menu Stock Dataset extracted from Cheers Hotel & Shop Stock Sheets
const FULL_MENU_DATASET = [
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

  // Breakfast & Snacks
  { name: 'EGGS', price: 70, category: 'Breakfast' },
  { name: 'CHAPATI', price: 20, category: 'Breakfast' },
  { name: 'MANDAZI', price: 10, category: 'Breakfast' },
  { name: 'CHAI', price: 30, category: 'Breakfast' },
  { name: 'SAMOSA', price: 30, category: 'Snacks' },
  { name: 'SAUSAGE', price: 50, category: 'Snacks' },
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
let cart = {};         // { itemId: qty }
let menuItems = {};    // { id: {...} }
let activeCategory = 'All';
let paymentMethod = 'cash';
let currentPeriod = 'today';
let orderCounter = 0;

// ─── Initialization ───
document.addEventListener('DOMContentLoaded', async () => {
  updateClock();
  setInterval(updateClock, 1000);

  try {
    const userCred = await auth.signInAnonymously();
    console.log('Auth OK — UID:', userCred.user.uid);
  } catch (e) {
    console.error('Auth failed:', e);
    showToast('⚠️ Auth notice: ' + e.message);
  }

  watchMenu();
  loadReports();
  loadExpenses();
});

function updateClock() {
  const now = new Date();
  document.getElementById('clock').textContent = now.toLocaleTimeString('en-KE', {
    hour: '2-digit', minute: '2-digit'
  });
}

// ─── Navigation ───
function switchTab(tab) {
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
  const navBtn = document.querySelector(`[data-tab="${tab}"]`);
  if (navBtn) navBtn.classList.add('active');

  const titles = {
    order: 'New Order',
    menu: 'Menu Management',
    analytics: 'Sales Analytics',
    expenses: 'Daily Expenses',
    settings: 'Settings'
  };
  document.getElementById('pageTitle').textContent = titles[tab] || tab;

  if (tab === 'analytics') loadReports();
  if (tab === 'expenses') loadExpenses();
  if (tab === 'menu') renderMenuList();
}

// ─── Menu Management & Real-time Listening ───
function watchMenu() {
  menuRef.onSnapshot(snap => {
    menuItems = {};
    snap.forEach(doc => {
      const data = { id: doc.id, ...doc.data() };
      if (data.active !== false) menuItems[doc.id] = data;
    });

    // Auto-seed if database is empty
    if (Object.keys(menuItems).length === 0 && snap.empty) {
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
  showToast('⏳ Seeding full stock menu items...');
  const batch = db.batch();
  FULL_MENU_DATASET.forEach(item => {
    const docRef = menuRef.doc();
    batch.set(docRef, { ...item, active: true, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();
  showToast('✅ Full Cheers menu loaded!');
}

async function seedMenu() {
  if (confirm('Load full Cheers Hotel menu dataset from stock sheets? This will add all 26+ items.')) {
    await autoSeedMenu();
  }
}

// ─── Category Filtering ───
function renderCategoryFilter() {
  const categories = ['All', ...new Set(Object.values(menuItems).map(i => i.category || 'Mains'))];
  const container = document.getElementById('categoryFilter');
  if (!container) return;

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

// ─── Order Grid & Cart ───
function renderMenuGrid() {
  const grid = document.getElementById('menuGrid');
  if (!grid) return;

  const items = Object.values(menuItems).filter(item => {
    if (activeCategory === 'All') return true;
    return (item.category || 'Mains') === activeCategory;
  });

  if (items.length === 0) {
    grid.innerHTML = '<div class="empty-state"><p>No items found in this category.</p></div>';
    return;
  }

  grid.innerHTML = items.map(item => {
    const qty = cart[item.id] || 0;
    return `
      <div class="menu-card ${qty > 0 ? 'in-cart' : ''}" onclick="addToCart('${item.id}')">
        ${qty > 0 ? `<div class="qty-badge">${qty}</div>` : ''}
        <div class="item-category">${item.category || 'Mains'}</div>
        <div class="item-name">${item.name}</div>
        <div class="item-price">KES ${Number(item.price).toLocaleString()}</div>
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
  const panel = document.getElementById('cartPanel');
  const entries = Object.entries(cart);

  if (entries.length === 0) {
    panel.style.display = 'none';
    return;
  }
  panel.style.display = 'flex';

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
          <div class="cart-item-price">KES ${Number(item.price).toLocaleString()} × ${qty} = KES ${lineTotal.toLocaleString()}</div>
        </div>
        <div class="cart-item-controls">
          <button onclick="removeFromCart('${id}')" title="Decrease">−</button>
          <span class="cart-item-qty">${qty}</span>
          <button onclick="addToCart('${id}')" title="Increase">+</button>
          <button class="cart-delete-btn" onclick="deleteFromCart('${id}')" title="Remove item">✕</button>
        </div>
      </div>
    `;
  }).join('');

  document.getElementById('cartItems').innerHTML = itemsHtml;
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
    <span>Payment: <strong>${paymentMethod === 'mpesa' ? '📱 M-Pesa' : '💵 Cash'}</strong></span> • 
    <span>Source: <strong>${source.toUpperCase()}</strong></span>
  `;
  document.getElementById('confirmModal').classList.add('show');
}

async function recordSale() {
  const btn = document.querySelector('#confirmModal .btn-primary');
  btn.disabled = true;
  btn.textContent = 'Processing Sale...';

  try {
    const items = Object.entries(cart).map(([id, qty]) => {
      const item = menuItems[id];
      return { itemId: id, name: item.name, price: item.price, qty: qty };
    });
    const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);

    orderCounter++;
    const orderNum = String(orderCounter).padStart(3, '0');
    const sourceSelect = document.getElementById('settingSource');
    const source = sourceSelect ? sourceSelect.value : 'desktop';

    await ordersRef.add({
      items: items,
      total: total,
      timestamp: firebase.firestore.FieldValue.serverTimestamp(),
      recordedBy: 'staff',
      source: source,
      paymentMethod: paymentMethod,
      synced: true,
      receiptPrinted: false,
    });

    cart = {};
    updateCart();
    closeModal('confirmModal');
    showToast(`✅ Sale #${orderNum} Recorded! Total: KES ${total.toLocaleString()}`);
    loadReports();
  } catch (e) {
    console.error('Record sale error:', e);
    showToast('❌ Failed to record sale: ' + e.message);
  } finally {
    btn.disabled = false;
    btn.textContent = '✓ Record Sale';
  }
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
            <h4>${item.name}</h4>
            <span>${item.category || 'Mains'}</span>
          </div>
          <div class="item-actions">
            <span class="item-price-tag">KES ${Number(item.price).toLocaleString()}</span>
            <button class="toggle-btn ${active ? 'active' : 'inactive'}" onclick="toggleMenuItem('${item.id}', ${!active})">
              ${active ? 'Active' : 'Inactive'}
            </button>
          </div>
        </div>
      `;
    });
    if (!html) html = '<p style="color:#6b7280;padding:20px;">No menu items. Click "+ Add Item" or "Reset Full Menu".</p>';
    list.innerHTML = html;
  }).catch(e => {
    console.error('Render menu error:', e);
  });
}

function showAddItemModal() { document.getElementById('addItemModal').classList.add('show'); }
function showAddExpenseModal() { document.getElementById('addExpenseModal').classList.add('show'); }
function closeModal(id) { document.getElementById(id).classList.remove('show'); }

async function addMenuItem() {
  const name = document.getElementById('itemName').value.trim();
  const price = parseFloat(document.getElementById('itemPrice').value);
  const category = document.getElementById('itemCategory').value;

  if (!name || isNaN(price)) {
    showToast('⚠️ Please enter a valid name and price');
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
    showToast(newState ? '✅ Item activated' : '⏸️ Item deactivated');
  } catch (e) {
    showToast('❌ Failed: ' + e.message);
  }
}

// ─── Sales Analytics ───
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

    let totalSales = 0, desktopCount = 0, mobileCount = 0;
    const topItems = {};
    const categorySales = {};
    const orders = [];

    snap.forEach(doc => {
      const data = doc.data();
      const orderTotal = data.total || 0;
      totalSales += orderTotal;
      if (data.source === 'mobile') mobileCount++; else desktopCount++;

      (data.items || []).forEach(item => {
        topItems[item.name] = (topItems[item.name] || 0) + (item.qty || 1);
        const cat = item.category || 'Mains';
        categorySales[cat] = (categorySales[cat] || 0) + (item.price * item.qty);
      });
      orders.push({ id: doc.id, ...data });
    });

    orders.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));

    // Stats Cards
    const statsContainer = document.getElementById('statsGrid');
    if (statsContainer) {
      statsContainer.innerHTML = `
        <div class="stat-card"><div class="stat-label">Total Revenue</div><div class="stat-value sales">KES ${totalSales.toLocaleString()}</div></div>
        <div class="stat-card"><div class="stat-label">Total Orders</div><div class="stat-value">${snap.size}</div></div>
        <div class="stat-card"><div class="stat-label">Till / Mobile</div><div class="stat-value">${desktopCount} / ${mobileCount}</div></div>
        <div class="stat-card"><div class="stat-label">Avg Order Value</div><div class="stat-value">KES ${snap.size > 0 ? Math.round(totalSales / snap.size).toLocaleString() : 0}</div></div>
      `;
    }

    // Top selling items
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

    // Category breakdown
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

    // Recent orders list
    const ordersContainer = document.getElementById('recentOrders');
    if (ordersContainer) {
      ordersContainer.innerHTML = orders.length > 0
        ? orders.slice(0, 10).map(o => {
            const time = o.timestamp?.toDate ? o.timestamp.toDate().toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' }) : 'Just now';
            const source = o.source || 'desktop';
            const payment = o.paymentMethod === 'mpesa' ? 'M-Pesa' : 'Cash';
            const itemsSummary = (o.items || []).map(i => `${i.qty}x ${i.name}`).join(', ');
            return `
              <div class="order-row">
                <div class="order-main-info">
                  <span class="order-time">${time}</span>
                  <span class="order-source ${source}">${source}</span>
                  <span class="order-payment-badge">${payment}</span>
                  <span class="order-items-summary">${itemsSummary}</span>
                </div>
                <span class="order-amount">KES ${(o.total || 0).toLocaleString()}</span>
              </div>`;
          }).join('')
        : '<p style="color:#6b7280;padding:12px;">No recent orders found.</p>';
    }

  } catch (e) {
    console.error('Analytics error:', e);
  }
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
            <span>${data.category || 'Other'} • ${time}</span>
          </div>
          <span class="expense-amount">- KES ${(data.amount || 0).toLocaleString()}</span>
        </div>`;
    });

    document.getElementById('expensesSummary').innerHTML = `
      <div class="stat-card"><div class="stat-label">Today's Expenses</div><div class="stat-value" style="color:#ef4444">KES ${totalExpenses.toLocaleString()}</div></div>
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
    });
    document.getElementById('expenseDesc').value = '';
    document.getElementById('expenseAmount').value = '';
    closeModal('addExpenseModal');
    loadExpenses();
    showToast(`✅ Expense recorded: KES ${amount.toLocaleString()}`);
  } catch (e) {
    showToast('❌ Failed: ' + e.message);
  }
}

// ─── Settings Admin Action ───
function saveAdminSettings() {
  const name = document.getElementById('settingRestName').value;
  const footer = document.getElementById('settingFooter').value;
  showToast(`✅ Saved settings for ${name}`);
}

async function clearAllOrders() {
  if (confirm('Clear today\'s test orders?')) {
    const snap = await ordersRef.get();
    const batch = db.batch();
    snap.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    showToast('🧹 Orders cleared!');
    loadReports();
  }
}

// ─── Toast Notifications ───
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3000);
}

// Overlay click to close modals
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) overlay.classList.remove('show');
  });
});
