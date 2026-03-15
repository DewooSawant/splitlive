import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { login, signup } from '../api/api';

function LoginPage() {
  const [isSignup, setIsSignup] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const { saveAuth } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    const data = isSignup
      ? await signup(name, email, password)
      : await login(email, password);

    if (data.token) {
      saveAuth(data.token, data.user);
      navigate('/groups');
    } else {
      setError(data.error || data.errors?.join(', ') || 'Something went wrong');
    }
  };

  return (
    <div className="page">
      <div className="card auth-card">
        <h1>SplitLive</h1>
        <p className="subtitle">Split expenses with friends, in real-time</p>

        <form onSubmit={handleSubmit}>
          {isSignup && (
            <input
              type="text"
              placeholder="Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          )}
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {error && <p className="error">{error}</p>}

          <button type="submit">
            {isSignup ? 'Sign Up' : 'Log In'}
          </button>
        </form>

        <p className="toggle">
          {isSignup ? 'Already have an account? ' : "Don't have an account? "}
          <span onClick={() => setIsSignup(!isSignup)}>
            {isSignup ? 'Log In' : 'Sign Up'}
          </span>
        </p>
      </div>
    </div>
  );
}

export default LoginPage;
