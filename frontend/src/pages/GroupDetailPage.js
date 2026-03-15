import { useState, useEffect, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { createConsumer } from '@rails/actioncable';
import { useAuth } from '../context/AuthContext';
import {
  getGroup, getExpenses, getBalances,
  createExpense, addMember, createSettlement
} from '../api/api';

function GroupDetailPage() {
  const { id } = useParams();
  const { token, user } = useAuth();
  const navigate = useNavigate();

  const [group, setGroup] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [balances, setBalances] = useState(null);

  // Form states
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('');
  const [memberEmail, setMemberEmail] = useState('');
  const [message, setMessage] = useState('');
  const [activeTab, setActiveTab] = useState('expenses');

  // ─── Load Data ─────────────────────────────────────

  useEffect(() => {
    if (!token) {
      navigate('/login');
      return;
    }
    loadAll();
  }, [id, token]);

  const loadAll = async () => {
    const [groupData, expensesData, balancesData] = await Promise.all([
      getGroup(token, id),
      getExpenses(token, id),
      getBalances(token, id),
    ]);
    setGroup(groupData);
    if (Array.isArray(expensesData)) setExpenses(expensesData);
    setBalances(balancesData);
  };

  // ─── WebSocket (Real-time) ─────────────────────────

  useEffect(() => {
    if (!token) return;

    const wsUrl = process.env.REACT_APP_WS_URL || 'ws://localhost:3000/cable';
    const cable = createConsumer(`${wsUrl}?token=${token}`);
    const subscription = cable.subscriptions.create(
      { channel: 'GroupChannel', group_id: id },
      {
        received(data) {
          loadAll();
        },
      }
    );

    return () => {
      subscription.unsubscribe();
      cable.disconnect();
    };
  }, [id, token]);

  // ─── Add Expense ──────────────────────────────────

  const handleAddExpense = async (e) => {
    e.preventDefault();
    setMessage('');

    const data = await createExpense(token, id, {
      description,
      amount: parseFloat(amount),
      category,
      split_type: 'equal',
    });

    if (data.id) {
      setDescription('');
      setAmount('');
      setCategory('');
      setMessage('Expense added!');
      loadAll();
    } else {
      setMessage(data.errors?.join(', ') || data.error || 'Failed to add expense');
    }
  };

  // ─── Add Member ───────────────────────────────────

  const handleAddMember = async (e) => {
    e.preventDefault();
    setMessage('');

    const data = await addMember(token, id, memberEmail);

    if (data.message) {
      setMemberEmail('');
      setMessage(data.message);
      loadAll();
    } else {
      setMessage(data.error || 'Failed to add member');
    }
  };

  // ─── Settle Up ────────────────────────────────────

  const handleSettle = async (payeeId, settleAmount) => {
    const data = await createSettlement(token, id, payeeId, settleAmount);
    if (data.id) {
      setMessage('Settlement recorded!');
      loadAll();
    }
  };

  // ─── useMemo: calculate my balance ────────────────

  const myBalance = useMemo(() => {
    if (!balances?.user_balances) return 0;
    const mine = balances.user_balances.find((b) => b.user.id === user?.id);
    return mine ? mine.balance : 0;
  }, [balances, user]);

  // ─── Render ───────────────────────────────────────

  if (!group) return <div className="page"><p>Loading...</p></div>;

  return (
    <div className="page">
      <div className="header">
        <div>
          <button onClick={() => navigate('/groups')} className="btn-back">Back</button>
          <h1>{group.name}</h1>
        </div>
        <div className="my-balance">
          <span>Your balance: </span>
          <span className={myBalance >= 0 ? 'positive' : 'negative'}>
            {myBalance >= 0 ? `+₹${myBalance.toFixed(2)}` : `-₹${Math.abs(myBalance).toFixed(2)}`}
          </span>
        </div>
      </div>

      {message && <p className="message">{message}</p>}

      {/* Tabs */}
      <div className="tabs">
        <button
          className={activeTab === 'expenses' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('expenses')}
        >
          Expenses
        </button>
        <button
          className={activeTab === 'balances' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('balances')}
        >
          Balances
        </button>
        <button
          className={activeTab === 'members' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('members')}
        >
          Members ({group.members?.length})
        </button>
      </div>

      {/* ─── Expenses Tab ─── */}
      {activeTab === 'expenses' && (
        <div>
          <form onSubmit={handleAddExpense} className="create-form">
            <input
              type="text"
              placeholder="Description (e.g. Dinner)"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              required
            />
            <input
              type="number"
              placeholder="Amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              step="0.01"
              required
            />
            <input
              type="text"
              placeholder="Category (e.g. food)"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
            />
            <button type="submit">Add Expense (Equal Split)</button>
          </form>

          <div className="expense-list">
            {expenses.length === 0 ? (
              <p className="empty">No expenses yet.</p>
            ) : (
              expenses.map((expense) => (
                <div key={expense.id} className="expense-card">
                  <div className="expense-header">
                    <strong>{expense.description}</strong>
                    <span className="expense-amount">₹{expense.amount.toFixed(2)}</span>
                  </div>
                  <p className="expense-meta">
                    Paid by {expense.paid_by.name} · {expense.split_type} split
                    {expense.category && ` · ${expense.category}`}
                  </p>
                  <div className="splits">
                    {expense.splits.map((split) => (
                      <span key={split.user_id} className="split-chip">
                        {split.name}: ₹{split.amount_owed.toFixed(2)}
                      </span>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* ─── Balances Tab ─── */}
      {activeTab === 'balances' && (
        <div>
          <h3>Who owes whom</h3>
          {balances?.simplified_debts?.length === 0 ? (
            <p className="empty">All settled up!</p>
          ) : (
            balances?.simplified_debts?.map((debt, index) => (
              <div key={index} className="balance-card">
                <p>
                  <strong>{debt.from.name}</strong> owes <strong>{debt.to.name}</strong>
                  {' '}₹{debt.amount.toFixed(2)}
                </p>
                {debt.from.id === user?.id && (
                  <button
                    onClick={() => handleSettle(debt.to.id, debt.amount)}
                    className="btn-settle"
                  >
                    Settle ₹{debt.amount.toFixed(2)}
                  </button>
                )}
              </div>
            ))
          )}

          <h3>Net Balances</h3>
          {balances?.user_balances?.map((b) => (
            <div key={b.user.id} className="balance-row">
              <span>{b.user.name}</span>
              <span className={b.balance >= 0 ? 'positive' : 'negative'}>
                {b.balance >= 0 ? `+₹${b.balance.toFixed(2)}` : `-₹${Math.abs(b.balance).toFixed(2)}`}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* ─── Members Tab ─── */}
      {activeTab === 'members' && (
        <div>
          <form onSubmit={handleAddMember} className="create-form">
            <input
              type="email"
              placeholder="Add member by email"
              value={memberEmail}
              onChange={(e) => setMemberEmail(e.target.value)}
              required
            />
            <button type="submit">Add Member</button>
          </form>

          <div className="member-list">
            {group.members?.map((member) => (
              <div key={member.id} className="member-card">
                <strong>{member.name}</strong>
                <span>{member.email}</span>
                {member.id === group.created_by?.id && (
                  <span className="badge">Creator</span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default GroupDetailPage;
