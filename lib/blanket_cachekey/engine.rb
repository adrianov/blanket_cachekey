module BlanketCachekey
  class Engine < ::Rails::Engine
    config.after_initialize do
      BlanketCachekey.db = SQLite3::Database.new Rails.root.join('tmp', 'blanket_cachekey.sqlite3').to_s
      BlanketCachekey.db.busy_timeout(1000)
      BlanketCachekey.db.execute("create table if not exists updates (name blob not null primary key, updated_at blob)")
      BlanketCachekey.select  = BlanketCachekey.db.prepare("select updated_at from updates where name = ?")
      BlanketCachekey.delete  = BlanketCachekey.db.prepare("delete from updates where name = ?")
      BlanketCachekey.replace = BlanketCachekey.db.prepare("replace into updates values (?, ?)")
    end
  end
end
