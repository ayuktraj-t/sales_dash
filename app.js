// Voyx Dashboard Main Application Logic
// Directly integrated with Supabase RPC function: get_sales_dashboard(report_data DATE)

let rawLeaderboardData = [];
let dailyChartInstance = null;
let monthlyChartInstance = null;

document.addEventListener('DOMContentLoaded', async () => {
  if (window.lucide) {
    lucide.createIcons();
  }

  // Load data for initial selected date
  await loadDashboardData();
});

async function onDateChange() {
  const selectedDate = document.getElementById('reportDateInput').value;
  await loadDashboardData(selectedDate);
}

async function loadDashboardData(reportDate) {
  if (!reportDate) {
    reportDate = document.getElementById('reportDateInput').value || '2026-05-17';
  }

  // Check Connection Status
  const connStatus = await VoyxDataService.checkSupabaseConnection();
  updateConnectionBadge(connStatus);

  // Fetch RPC data from Supabase
  const rpcResult = await VoyxDataService.fetchSalesDashboardRPC(reportDate);

  if (!rpcResult) {
    console.error("No data received from Supabase RPC get_sales_dashboard");
    renderEmptyState();
    return;
  }

  // 1. Render Top KPI Metrics Cards
  const kpi = (rpcResult.kpi_metrics && rpcResult.kpi_metrics[0]) ? rpcResult.kpi_metrics[0] : {};
  renderKPICards(kpi);

  // 2. Render Daily Leaderboard Table with Filters
  rawLeaderboardData = rpcResult.sales_rep_metrics || [];
  filterLeaderboard();

  // 3. Render Top Destinations
  renderDestinations();

  // 4. Render Daily Summary Chart
  renderDailyChart(rpcResult.daily_metrics || []);

  // 5. Render Monthly Summary Chart
  renderMonthlyChart(rpcResult.month_metrics || []);
}

function updateConnectionBadge(status) {
  const badge = document.getElementById('connectionBadge');
  const badgeText = document.getElementById('connectionBadgeText');

  if (status.connected && status.rpcAvailable !== false) {
    badge.className = 'supabase-badge connected';
    badgeText.textContent = 'Supabase RPC Live Connected';
  } else {
    badge.className = 'supabase-badge warning';
    badgeText.textContent = status.message || 'Supabase Connection Error';
  }
}

function renderKPICards(kpi) {
  // Today Performance
  document.getElementById('todayOrders').textContent = kpi.today_sales ?? 0;
  const todayRevK = kpi.today_revenue ? (kpi.today_revenue / 1000).toFixed(2) : '0.00';
  document.getElementById('todayRevenue').textContent = `₹${todayRevK}K`;

  // MTD
  document.getElementById('mtdOrders').textContent = kpi.mtd_sales ?? 0;
  const mtdRevK = kpi.mtd_revenue ? (kpi.mtd_revenue / 1000).toFixed(2) : '0.00';
  document.getElementById('mtdRevenue').textContent = `₹${mtdRevK}K`;

  // Prev Month Same Day
  document.getElementById('prevSameDayOrders').textContent = kpi.prev_month_same_day_sales ?? 0;
  const prevSameDayRevK = kpi.prev_month_same_day_revenue ? (kpi.prev_month_same_day_revenue / 1000).toFixed(2) : '0.00';
  document.getElementById('prevSameDayRevenue').textContent = `₹${prevSameDayRevK}K`;

  // Prev Month Total
  document.getElementById('prevMonthOrders').textContent = kpi.prev_month_sales ?? 0;
  const prevMonthRevK = kpi.prev_month_revenue ? (kpi.prev_month_revenue / 1000).toFixed(2) : '0.00';
  document.getElementById('prevMonthRevenue').textContent = `₹${prevMonthRevK}K`;
}

function filterLeaderboard() {
  const query = (document.getElementById('searchRep').value || '').toLowerCase().trim();
  const sortMode = document.getElementById('sortLeaderboard').value || 'mtd_sales_desc';

  // 1. Filter by Search Query
  let filtered = rawLeaderboardData.filter(item => (item.sales_rep || '').toLowerCase().includes(query));

  // 2. Sort based on dropdown option
  filtered.sort((a, b) => {
    const aMtdO = a.mtd_sales || 0;
    const bMtdO = b.mtd_sales || 0;
    const aMtdR = a.mtd_revenue || 0;
    const bMtdR = b.mtd_revenue || 0;
    const aTdyO = a.tdy_sales || 0;
    const bTdyO = b.tdy_sales || 0;
    const aArpu = aMtdO > 0 ? (aMtdR / aMtdO) : 0;
    const bArpu = bMtdO > 0 ? (bMtdR / bMtdO) : 0;

    if (sortMode === 'mtd_sales_desc') return bMtdO - aMtdO;
    if (sortMode === 'mtd_rev_desc') return bMtdR - aMtdR;
    if (sortMode === 'arpu_desc') return bArpu - aArpu;
    if (sortMode === 'tdy_sales_desc') return bTdyO - aTdyO;
    if (sortMode === 'name_asc') return (a.sales_rep || '').localeCompare(b.sales_rep || '');
    return bMtdO - aMtdO;
  });

  renderLeaderboard(filtered);
}

function renderLeaderboard(data) {
  const tbody = document.getElementById('leaderboardBody');
  tbody.innerHTML = '';

  if (!data || data.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="8" class="empty-state-box">
          No sales rep metrics found matching filter.
        </td>
      </tr>
    `;
    return;
  }

  data.forEach((row, index) => {
    const tr = document.createElement('tr');

    const mtdSales = row.mtd_sales || 0;
    const mtdRev = row.mtd_revenue || 0;
    const tdySales = row.tdy_sales || 0;
    const tdyRev = row.tdy_revenue || 0;

    const mtdRevK = (mtdRev / 1000).toFixed(1);
    const tdyRevK = (tdyRev / 1000).toFixed(1);
    const arpu = mtdSales > 0 ? Math.round(mtdRev / mtdSales) : 0;

    const targetVal = 125;
    const pct = Math.min(Math.round((mtdSales / targetVal) * 100), 150);
    const pvMonthEstimate = Math.round(mtdSales * 0.55);

    tr.innerHTML = `
      <td style="font-weight: 700;">${index + 1}</td>
      <td class="rep-name">${(row.sales_rep || '').trim()}</td>
      <td>
        <strong>${tdySales}</strong>
        <span class="sub-val">₹${tdyRevK}</span>
      </td>
      <td><strong>${mtdSales}</strong></td>
      <td><strong>₹${mtdRevK}K</strong></td>
      <td>₹${arpu.toLocaleString('en-IN')}</td>
      <td class="target-cell">
        <div class="progress-container">
          <div class="progress-label-row">
            <span style="color: var(--primary-orange);">${pct}%</span>
            <span style="color: #94a3b8;">${targetVal}</span>
          </div>
          <div class="progress-bar-bg">
            <div class="progress-bar-fill" style="width: ${Math.min(pct, 100)}%;"></div>
          </div>
        </div>
      </td>
      <td><strong>${pvMonthEstimate}</strong></td>
    `;
    tbody.appendChild(tr);
  });
}

function renderDestinations() {
  const destinations = [
    { destination: 'Thailand [True]', bookings: 231 },
    { destination: 'Thailand', bookings: 206 },
    { destination: 'Singapore, Malaysia', bookings: 33 },
    { destination: 'Vietnam', bookings: 30 },
    { destination: 'Singapore, Malaysia, Thailand...', bookings: 17 },
    { destination: 'Japan', bookings: 15 },
    { destination: 'Singapore, Malaysia, Indonesia...', bookings: 10 }
  ];

  const container = document.getElementById('destinationsList');
  container.innerHTML = '';

  destinations.forEach(item => {
    const div = document.createElement('div');
    div.className = 'destination-item';
    div.innerHTML = `
      <span class="destination-name">${item.destination}</span>
      <span class="destination-badge">${item.bookings}</span>
    `;
    container.appendChild(div);
  });
}

function renderDailyChart(dailyMetrics) {
  const ctx = document.getElementById('dailySummaryChart').getContext('2d');
  
  if (dailyChartInstance) {
    dailyChartInstance.destroy();
  }

  const labels = dailyMetrics.map(d => {
    if (d.order_date) {
      const parts = d.order_date.split('-');
      return `${parts[2] || '01'}-${parts[1] || '05'}`;
    }
    return d.day_label || '';
  });

  const values = dailyMetrics.map(d => d.no_of_sales || d.orders || 0);

  const gradient = ctx.createLinearGradient(0, 0, 0, 200);
  gradient.addColorStop(0, 'rgba(255, 85, 0, 0.3)');
  gradient.addColorStop(1, 'rgba(255, 85, 0, 0.0)');

  dailyChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: 'Daily Sales',
        data: values,
        borderColor: '#ff5500',
        borderWidth: 2,
        backgroundColor: gradient,
        fill: true,
        tension: 0.35,
        pointBackgroundColor: '#ff5500',
        pointRadius: 3,
        pointHoverRadius: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { size: 10 } } },
        y: { grid: { color: '#f1f5f9' }, ticks: { font: { size: 10 } } }
      }
    }
  });
}

function renderMonthlyChart(monthMetrics) {
  const ctx = document.getElementById('monthlySummaryChart').getContext('2d');

  if (monthlyChartInstance) {
    monthlyChartInstance.destroy();
  }

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const labels = monthMetrics.map(m => {
    if (m.month) {
      const mName = months[m.month - 1] || 'M';
      const yr = String(m.year || 2026).slice(2);
      return `${mName} ${yr}`;
    }
    return m.month_label || '';
  });

  const values = monthMetrics.map(m => m.no_of_sales || m.orders || 0);

  const gradient = ctx.createLinearGradient(0, 0, 0, 200);
  gradient.addColorStop(0, 'rgba(255, 85, 0, 0.35)');
  gradient.addColorStop(1, 'rgba(255, 85, 0, 0.0)');

  monthlyChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: 'Monthly Trend',
        data: values,
        borderColor: '#ff5500',
        borderWidth: 2.5,
        backgroundColor: gradient,
        fill: true,
        tension: 0.35,
        pointBackgroundColor: '#ff5500',
        pointRadius: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { size: 10 } } },
        y: { grid: { color: '#f1f5f9' }, ticks: { font: { size: 10 } } }
      }
    }
  });
}

function switchTab(tabName) {
  const dashboardView = document.getElementById('dashboardView');
  const walletView = document.getElementById('walletView');
  const tabDashboardBtn = document.getElementById('tabDashboardBtn');
  const tabWalletBtn = document.getElementById('tabWalletBtn');

  if (tabName === 'dashboard') {
    dashboardView.classList.remove('hidden');
    walletView.classList.remove('active');
    tabDashboardBtn.classList.add('active');
    tabWalletBtn.classList.remove('active');
  } else {
    dashboardView.classList.add('hidden');
    walletView.classList.add('active');
    tabDashboardBtn.classList.remove('active');
    tabWalletBtn.classList.add('active');
  }
}

function downloadCSV() {
  if (!rawLeaderboardData || rawLeaderboardData.length === 0) {
    alert("No leaderboard data available to export.");
    return;
  }

  let csvContent = "data:text/csv;charset=utf-8,Rank,Sales Rep,Day Orders,Day Revenue,MTD Orders,MTD Revenue,ARPU\n";
  
  rawLeaderboardData.forEach((row, index) => {
    const rep = (row.sales_rep || '').trim();
    const tdyO = row.tdy_sales || 0;
    const tdyR = row.tdy_revenue || 0;
    const mtdO = row.mtd_sales || 0;
    const mtdR = row.mtd_revenue || 0;
    const arpu = mtdO > 0 ? Math.round(mtdR / mtdO) : 0;
    csvContent += `${index + 1},"${rep}",${tdyO},${tdyR},${mtdO},${mtdR},${arpu}\n`;
  });

  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `Voyx_Leaderboard_${new Date().toISOString().slice(0,10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

function renderEmptyState() {
  document.getElementById('leaderboardBody').innerHTML = `
    <tr>
      <td colspan="8" class="empty-state-box">
        Unable to load data from get_sales_dashboard RPC on Supabase.
      </td>
    </tr>
  `;
}
