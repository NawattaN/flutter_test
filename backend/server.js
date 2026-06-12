import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  host: process.env.PG_HOST,
  port: Number(process.env.PG_PORT || 5432),
  database: process.env.PG_DATABASE,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
});

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/habits', async (req, res) => {
  // รับค่า page และ limit จาก query string (เช่น /habits?page=1&limit=20)
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const offset = (page - 1) * limit;

  try {
    // ใช้ LIMIT และ OFFSET ในการแบ่งหน้าข้อมูลบน SQL
    const result = await pool.query(
      'SELECT * FROM habits ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({ error: 'Unable to fetch habits securely' });
  }
});

app.post('/habits', async (req, res) => {
  const { title, details, done = false } = req.body;

  if (!title || typeof title !== 'string') {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO habits (title, details, done) VALUES ($1, $2, $3) RETURNING *',
      [title.trim(), details || '', done]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Unable to save habit' });
  }
});

app.put('/habits/:id', async (req, res) => {
  const { id } = req.params;
  const { done } = req.body;

  if (typeof done !== 'boolean') {
    return res.status(400).json({ error: 'Invalid done value' });
  }

  try {
    const result = await pool.query(
      'UPDATE habits SET done = $1 WHERE id = $2 RETURNING *',
      [done, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Habit not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Unable to update habit' });
  }
});

app.listen(process.env.PORT || 3000, () => {
  console.log(`Server running on port ${process.env.PORT || 3000}`);
});