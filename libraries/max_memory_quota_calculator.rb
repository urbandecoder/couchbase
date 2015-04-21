module Couchbase
  class MaxMemoryQuotaCalculator
    MAX_MEMORY_PERCENT = 0.8
    RESERVE_BYTES = 1024 * 1024 * 1024 # 1 gigabyte

    attr_reader :total_in_bytes

    class << self
      def from_node(node)
        if node["memory"].nil? && node['platform_family'] != 'windows'
          # Usually nodes have this set, except if running in RSpec without Fauxhai,
          # so set some dummy value
          new kilobytes_to_bytes 0.to_i
        else
          new kilobytes_to_bytes total_memory(node)
        end
      end

      protected

      def total_memory(node)
        if node['platform_family'] == 'windows'
          wmi = ::WIN32OLE.connect('winmgmts://')
          res = wmi.ExecQuery('select Capacity from Win32_PhysicalMemory')
          mem = res.each.next.capacity
          mem.to_i / 1024
        else
          node['memory']['total'].to_i
        end
      end

      def kilobytes_to_bytes(kilobytes)
        kilobytes * 1024
      end
    end

    def initialize(total_in_bytes)
      @total_in_bytes = total_in_bytes
    end

    def in_megabytes
      [max_megabytes_by_percent, max_megabytes_by_reserve].max
    end

    protected

    def max_megabytes_by_percent
      bytes_to_megabytes total_in_bytes * MAX_MEMORY_PERCENT
    end

    def max_megabytes_by_reserve
      bytes_to_megabytes total_in_bytes - RESERVE_BYTES
    end

    def bytes_to_megabytes(bytes)
      (bytes / 1024 / 1024).to_i
    end
  end
end
