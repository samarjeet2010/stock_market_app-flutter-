const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { db, userRowToJson } = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function signToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

router.post('/signup', async (req, res) => {
  try {
    const { email, password, name, riskProfile } = req.body || {};
    if (!email || !password || !name || !riskProfile) {
      return res.status(400).json({ error: 'email, password, name and riskProfile are required' });
    }

    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const now = new Date().toISOString();
    const id = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);
    const startingBalance = Number(process.env.STARTING_BALANCE || 100000);

    db.prepare(`
      INSERT INTO users (id, email, password_hash, name, virtual_balance, risk_profile, avatar_data, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, NULL, ?, ?)
    `).run(id, email.toLowerCase(), passwordHash, name, startingBalance, riskProfile, now, now);

    db.prepare(`INSERT INTO watchlist (user_id, symbol) VALUES (?, ?), (?, ?), (?, ?), (?, ?)`).run(
      id, 'AAPL', id, 'GOOGL', id, 'MSFT', id, 'TSLA'
    );

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
    const token = signToken(id);
    res.status(201).json({ token, user: userRowToJson(user) });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ error: 'Signup failed' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }

    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = signToken(user.id);
    res.json({ token, user: userRowToJson(user) });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

router.get('/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ user: userRowToJson(user) });
});

router.put('/profile', requireAuth, (req, res) => {
  const { name, riskProfile } = req.body || {};
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  if (!user) return res.status(404).json({ error: 'User not found' });

  const now = new Date().toISOString();
  db.prepare('UPDATE users SET name = ?, risk_profile = ?, updated_at = ? WHERE id = ?').run(
    name ?? user.name,
    riskProfile ?? user.risk_profile,
    now,
    req.userId
  );

  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  res.json({ user: userRowToJson(updated) });
});

router.put('/avatar', requireAuth, (req, res) => {
  const { avatarData } = req.body || {};
  const now = new Date().toISOString();
  // Stored directly on the user row as a base64 string (no separate file
  // storage needed for this use case).
  db.prepare('UPDATE users SET avatar_data = ?, updated_at = ? WHERE id = ?').run(
    avatarData ?? null,
    now,
    req.userId
  );
  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  res.json({ user: userRowToJson(updated) });
});

module.exports = router;
