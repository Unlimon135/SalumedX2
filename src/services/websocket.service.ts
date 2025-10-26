import { WebSocketServer, WebSocket } from 'ws';
import { getNotifications, addNotification, deleteNotification } from './notification.service.js';

interface Message {
  action: string;
  data?: any;
}

const clients = new Set<WebSocket>();

export function setupWebSocket(server: any) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws: WebSocket) => {
    console.log('🟢 Cliente conectado');
    clients.add(ws);

    ws.on('message', async (raw) => {
      try {
        const msg: Message = JSON.parse(raw.toString());
        await handleMessage(ws, msg);
      } catch (error) {
        console.error('Error al procesar mensaje:', error);
        ws.send(JSON.stringify({ event: 'error', message: 'Formato de mensaje inválido' }));
      }
    });

    ws.on('close', () => {
      clients.delete(ws);
      console.log('🔴 Cliente desconectado');
    });
  });

  console.log('🚀 Servidor WebSocket listo en ruta /ws');
}

async function handleMessage(ws: WebSocket, msg: Message) {
  switch (msg.action) {
    case 'get':
      const data = await getNotifications();
      ws.send(JSON.stringify({ event: 'notifications', data }));
      break;

    case 'getById':
      if (!msg.data?.id) return ws.send(JSON.stringify({ event: 'error', message: 'ID requerido' }));
      const note = await getNotifications();
      ws.send(JSON.stringify({ event: 'notification', data: note }));
      break;

    case 'add':
      if (!msg.data?.title || !msg.data?.message)
        return ws.send(JSON.stringify({ event: 'error', message: 'Datos incompletos' }));
      const newNote = await addNotification(msg.data);
      broadcast({ event: 'new_notification', data: newNote });
      break;

    case 'delete':
      if (!msg.data?.id)
        return ws.send(JSON.stringify({ event: 'error', message: 'ID requerido' }));
      const ok = await deleteNotification(msg.data.id);
      broadcast({ event: 'deleted_notification', data: { success: ok, id: msg.data.id } });
      break;

    default:
      ws.send(JSON.stringify({ event: 'error', message: 'Acción no reconocida' }));
  }
}

export function broadcast(message: any) {
  const msgString = JSON.stringify(message);
  for (const client of clients) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msgString);
    }
  }
}
