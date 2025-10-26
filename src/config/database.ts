import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

export const pool = new Pool({
  user: process.env.PG_USER,
  host: process.env.PG_HOST,
  database: process.env.PG_DB,
  password: process.env.PG_PASSWORD,
  port: Number(process.env.PG_PORT),
});

pool.connect()
  .then(() => console.log('✅ Conectado a PostgreSQL'))
  .catch((err: any) => console.error('❌ Error en la conexión a PostgreSQL:', err));
