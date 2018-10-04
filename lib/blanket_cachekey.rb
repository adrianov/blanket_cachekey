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

        def find(*ids)
          key = "#{self.blanket_cachekey}|find|#{ids.inspect}"
          Rails.cache.fetch(key) do
            super
          end
        end

        def find_by(arg, *args)
          key = "#{self.blanket_cachekey}|find_by|#{arg.inspect}"
          if cacheable_opts?(arg)
            Rails.cache.fetch(key) do
              super
            end
          else
            super
          end
        end

        def where(opts = :chain, *rest)
          key = "#{self.blanket_cachekey}|where|#{opts.inspect}"
          if cacheable_opts?(opts)
            Rails.cache.fetch(key) do
              super.load
            end
          else
            super
          end
        end

        def cacheable_opts?(opts)
          opts.class == Hash && opts.values.all? { |v| v.class.in? [String, Integer, Float, NilClass, TrueClass, FalseClass] }
        end
      end

    end

  end

end
