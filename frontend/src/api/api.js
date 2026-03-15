const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1';

function getHeaders(token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

// ─── Auth ────────────────────────────────────────────

export async function signup(name, email, password) {
  const response = await fetch(`${API_URL}/auth/signup`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify({ name, email, password }),
  });
  return response.json();
}

export async function login(email, password) {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify({ email, password }),
  });
  return response.json();
}

// ─── Groups ──────────────────────────────────────────

export async function getGroups(token) {
  const response = await fetch(`${API_URL}/groups`, {
    headers: getHeaders(token),
  });
  return response.json();
}

export async function getGroup(token, groupId) {
  const response = await fetch(`${API_URL}/groups/${groupId}`, {
    headers: getHeaders(token),
  });
  return response.json();
}

export async function createGroup(token, name) {
  const response = await fetch(`${API_URL}/groups`, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify({ name }),
  });
  return response.json();
}

export async function addMember(token, groupId, email) {
  const response = await fetch(`${API_URL}/groups/${groupId}/members`, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify({ email }),
  });
  return response.json();
}

// ─── Expenses ────────────────────────────────────────

export async function getExpenses(token, groupId) {
  const response = await fetch(`${API_URL}/groups/${groupId}/expenses`, {
    headers: getHeaders(token),
  });
  return response.json();
}

export async function createExpense(token, groupId, expenseData) {
  const response = await fetch(`${API_URL}/groups/${groupId}/expenses`, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify(expenseData),
  });
  return response.json();
}

// ─── Balances ────────────────────────────────────────

export async function getBalances(token, groupId) {
  const response = await fetch(`${API_URL}/groups/${groupId}/balances`, {
    headers: getHeaders(token),
  });
  return response.json();
}

// ─── Settlements ─────────────────────────────────────

export async function createSettlement(token, groupId, payeeId, amount) {
  const response = await fetch(`${API_URL}/groups/${groupId}/settlements`, {
    method: 'POST',
    headers: getHeaders(token),
    body: JSON.stringify({ payee_id: payeeId, amount }),
  });
  return response.json();
}
