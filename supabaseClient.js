// Supabase Client Setup & RPC Integration
// Connects to project: https://pcenxwfhavneypapwbxi.supabase.co
// Calls RPC function: get_sales_dashboard(report_data DATE)

let supabaseClient = null;

function initSupabase() {
  const url = window.ENV ? window.ENV.SUPABASE_URL : "https://taspkwwknwopbhqphxng.supabase.co";
  const key = window.ENV ? window.ENV.SUPABASE_ANON_KEY : "sb_publishable_wOsI0n5Z3Mj1i0VUiM7b4Q_dxvnmBmY";

  if (window.supabase && typeof window.supabase.createClient === 'function') {
    try {
      supabaseClient = window.supabase.createClient(url, key);
      console.log("Connected to Supabase Project:", url);
    } catch (e) {
      console.error("Error creating Supabase client:", e);
    }
  } else {
    console.error("Supabase JS Library not found!");
  }
}

async function checkSupabaseConnection() {
  if (!supabaseClient) initSupabase();
  if (!supabaseClient) {
    return { connected: false, message: 'Supabase library not loaded' };
  }

  try {
    const { data, error } = await supabaseClient.rpc('get_sales_dashboard', { report_data: '2026-05-17' });
    if (error) {
      console.warn("RPC call check:", error.message);
      return { connected: true, rpcAvailable: false, message: `Connected (RPC Error: ${error.message})` };
    }
    return { connected: true, rpcAvailable: true, message: 'Live Connected to Supabase RPC (get_sales_dashboard)' };
  } catch (err) {
    return { connected: false, rpcAvailable: false, message: `Connection Error: ${err.message}` };
  }
}

// Call RPC function get_sales_dashboard(report_data DATE)
async function fetchSalesDashboardRPC(reportDate = '2026-05-17') {
  if (!supabaseClient) initSupabase();
  if (!supabaseClient) return null;

  try {
    const { data, error } = await supabaseClient.rpc('get_sales_dashboard', { report_data: reportDate });
    if (error) {
      console.error("RPC get_sales_dashboard error:", error);
      return null;
    }
    if (data && data.length > 0) {
      return data[0]; // returns object with { daily_metrics, month_metrics, kpi_metrics, sales_rep_metrics }
    }
  } catch (err) {
    console.error("Exception calling get_sales_dashboard RPC:", err);
  }
  return null;
}

window.VoyxDataService = {
  initSupabase,
  checkSupabaseConnection,
  fetchSalesDashboardRPC
};
