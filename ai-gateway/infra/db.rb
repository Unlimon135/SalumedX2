# Base de datos para historial de chat (opcional)
# Usar SQLite para simplicidad

require 'sqlite3'

class DB
  def self.instance
    @instance ||= new
  end

  def initialize
    @db = SQLite3::Database.new 'chat_history.db'
    create_tables
  end

  def save_message(user_id, message, role = 'user')
    @db.execute(
      'INSERT INTO messages (user_id, message, role, created_at) VALUES (?, ?, ?, ?)',
      [user_id, message, role, Time.now.to_i]
    )
  end

  def get_history(user_id, limit = 10)
    @db.execute(
      'SELECT * FROM messages WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
      [user_id, limit]
    )
  end

  private

  def create_tables
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        message TEXT,
        role TEXT,
        created_at INTEGER
      );
    SQL
  end
end
