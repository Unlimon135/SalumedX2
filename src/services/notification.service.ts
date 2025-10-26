import { pool } from '../config/database.js';
import { Notification } from '../models/notification.model.js';

// Obtener todas las notificaciones
export async function getNotifications(): Promise<Notification[]> {
  const result = await pool.query('SELECT * FROM notifications ORDER BY created_at DESC');
  return result.rows;
}

// Obtener una notificación por ID
export async function getNotificationById(id: number): Promise<Notification | null> {
  const result = await pool.query('SELECT * FROM notifications WHERE id = $1', [id]);
  return result.rows[0] || null;
}

// Crear una nueva notificación
export async function addNotification(data: Omit<Notification, 'id'>): Promise<Notification> {
  const result = await pool.query(
    'INSERT INTO notifications (title, message) VALUES ($1, $2) RETURNING *',
    [data.title, data.message]
  );
  return result.rows[0];
}

// Eliminar una notificación
export async function deleteNotification(id: number): Promise<boolean> {
  const result = await pool.query('DELETE FROM notifications WHERE id = $1', [id]);
  return result.rowCount! > 0;
}
