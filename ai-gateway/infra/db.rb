# Base de datos para historial de chat
# Usar SQLite para simplicidad

require 'sqlite3'

class DB
  def self.instance
    @instance ||= new
  end

  def initialize
    db_path = File.join(Dir.pwd, 'chat_history.db')
    @db = SQLite3::Database.new(db_path)
    create_tables
    puts "📦 Base de datos SQLite: #{db_path}"
  end

  def save_message(user_id, message, role = 'user')
    return if message.nil? || message.strip.empty?
    
    @db.execute(
      'INSERT INTO messages (user_id, message, role, created_at) VALUES (?, ?, ?, ?)',
      [user_id, message, role, Time.now.to_i]
    )
    puts "💾 Mensaje guardado: #{role} - #{user_id}"
  rescue StandardError => e
    puts "❌ Error guardando mensaje: #{e.message}"
  end

  def get_history(user_id, limit = 10)
    @db.execute(
      'SELECT * FROM messages WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
      [user_id, limit]
    )
  rescue StandardError => e
    puts "❌ Error obteniendo historial: #{e.message}"
    []
  end
  
  def clear_history(user_id)
    @db.execute('DELETE FROM messages WHERE user_id = ?', [user_id])
    puts "🗑️ Historial eliminado para: #{user_id}"
  rescue StandardError => e
    puts "❌ Error eliminando historial: #{e.message}"
  end
  
  def stats
    total = @db.execute('SELECT COUNT(*) FROM messages')[0][0]
    users = @db.execute('SELECT COUNT(DISTINCT user_id) FROM messages')[0][0]
    
    { total_messages: total, unique_users: users }
  rescue StandardError => e
    puts "❌ Error obteniendo estadísticas: #{e.message}"
    { total_messages: 0, unique_users: 0 }
  end

  private

  def create_tables
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        message TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        created_at INTEGER NOT NULL
      );
    SQL
    
    # Crear índices por separado
    @db.execute 'CREATE INDEX IF NOT EXISTS idx_user_id ON messages(user_id);'
    @db.execute 'CREATE INDEX IF NOT EXISTS idx_created_at ON messages(created_at);'
    
    puts "✅ Tabla 'messages' lista"
  rescue StandardError => e
    puts "❌ Error creando tablas: #{e.message}"
  end
end
