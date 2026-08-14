import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Database from 'better-sqlite3';

const app = express();
const db = new Database(process.env.DB_FILE || 'roshab_tasks.sqlite');
const port = Number(process.env.PORT || 8080);
const secret = process.env.JWT_SECRET;

if (!secret) {
  console.error('JWT_SECRET is required');
  process.exit(1);
}

app.use(cors());
app.use(express.json({ limit: '1mb' }));

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS task_blobs (
    user_id INTEGER PRIMARY KEY,
    payload TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`);

const sign = (userId) => jwt.sign({ sub: userId }, secret, { expiresIn: '30d' });

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const payload = jwt.verify(token, secret);
    req.userId = Number(payload.sub);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

app.get('/health', (_req, res) => res.json({ ok: true, service: 'Roshab Tasks Sync' }));

app.post('/auth/register', async (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  if (!email || password.length < 8) return res.status(400).json({ error: 'Email and password (8+ chars) are required' });
  try {
    const hash = await bcrypt.hash(password, 12);
    const result = db.prepare('INSERT INTO users (email,password_hash,created_at) VALUES (?,?,?)').run(email, hash, new Date().toISOString());
    return res.status(201).json({ token: sign(result.lastInsertRowid), email });
  } catch (error) {
    if (String(error).includes('UNIQUE')) return res.status(409).json({ error: 'Account already exists' });
    return res.status(500).json({ error: 'Registration failed' });
  }
});

app.post('/auth/login', async (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  const user = db.prepare('SELECT * FROM users WHERE email=?').get(email);
  if (!user || !(await bcrypt.compare(password, user.password_hash))) return res.status(401).json({ error: 'Invalid credentials' });
  res.json({ token: sign(user.id), email });
});

app.get('/tasks', auth, (req, res) => {
  const row = db.prepare('SELECT payload FROM task_blobs WHERE user_id=?').get(req.userId);
  if (!row) return res.json([]);
  try { return res.json(JSON.parse(row.payload)); } catch { return res.status(500).json({ error: 'Stored data is invalid' }); }
});

app.put('/tasks', auth, (req, res) => {
  const tasks = Array.isArray(req.body?.tasks) ? req.body.tasks : [];
  const payload = JSON.stringify(tasks);
  db.prepare(`INSERT INTO task_blobs(user_id,payload,updated_at) VALUES(?,?,?)
    ON CONFLICT(user_id) DO UPDATE SET payload=excluded.payload, updated_at=excluded.updated_at`).run(req.userId, payload, new Date().toISOString());
  res.json({ ok: true, count: tasks.length });
});

app.listen(port, () => console.log(`Roshab Tasks Sync running on :${port}`));
