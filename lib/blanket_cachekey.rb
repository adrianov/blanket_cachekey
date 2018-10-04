require 'blanket_cachekey/version'
require 'rails'
require 'blanket_cachekey/engine'

module BlanketCachekey

  class << self
    attr_accessor :db, :select, :delete, :replace
  end


  def self.included(model)
    model.class_eval do

      after_save :invalidate_blanket_cachekey
      after_destroy :invalidate_blanket_cachekey

      private

      def invalidate_blanket_cachekey
        self.class.invalidate_blanket_cachekey
      end

      class << self
        def blanket_cachekey
          rows = BlanketCachekey.select.execute!(self.table_name)
          updated_at = if rows.empty?
            now = Time.now
            time = "#{now.to_i}:#{now.nsec}"
            BlanketCachekey.replace.execute!(self.table_name, time)
            time
          else
            rows.first.first
          end

          "#{self.table_name}:#{updated_at}"
        end

        def invalidate_blanket_cachekey
          BlanketCachekey.delete.execute!(self.table_name)
        end
      end

    end

  end

end
