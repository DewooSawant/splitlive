import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { getGroups, createGroup } from '../api/api';

function GroupsPage() {
  const [groups, setGroups] = useState([]);
  const [newGroupName, setNewGroupName] = useState('');
  const [error, setError] = useState('');

  const { token, user, logout } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!token) {
      navigate('/login');
      return;
    }
    loadGroups();
  }, [token]);

  const loadGroups = async () => {
    const data = await getGroups(token);
    if (Array.isArray(data)) {
      setGroups(data);
    }
  };

  const handleCreateGroup = async (e) => {
    e.preventDefault();
    setError('');

    if (!newGroupName.trim()) return;

    const data = await createGroup(token, newGroupName);
    if (data.id) {
      setNewGroupName('');
      loadGroups();
    } else {
      setError(data.errors?.join(', ') || 'Failed to create group');
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="page">
      <div className="header">
        <h1>My Groups</h1>
        <div className="header-right">
          <span>Hi, {user?.name}</span>
          <button onClick={handleLogout} className="btn-secondary">Logout</button>
        </div>
      </div>

      <form onSubmit={handleCreateGroup} className="create-form">
        <input
          type="text"
          placeholder="New group name (e.g. Goa Trip)"
          value={newGroupName}
          onChange={(e) => setNewGroupName(e.target.value)}
        />
        <button type="submit">Create Group</button>
      </form>

      {error && <p className="error">{error}</p>}

      <div className="group-list">
        {groups.length === 0 ? (
          <p className="empty">No groups yet. Create one above!</p>
        ) : (
          groups.map((group) => (
            <Link to={`/groups/${group.id}`} key={group.id} className="group-card">
              <h3>{group.name}</h3>
              <p>{group.members_count} members</p>
            </Link>
          ))
        )}
      </div>
    </div>
  );
}

export default GroupsPage;
