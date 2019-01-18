Q::package(:"gio-2.0")

namespace module Q
  namespace module File
    class Monitor
      @file    = :GLib::File
      @monitor = :GLib::FileMonitor

      delegate; def monitor_cb(src: :GLib::File?, dest: :GLib::File?, evt: :GLib::FileMonitorEvent); end
      delegate; def event_cb(file: :GLib::File);   end

      @created_cb = :event_cb
      @deleted_cb = :event_cb
       
      def self.new(pth:string, cb: :monitor_cb?)
        @file = `GLib.File.new_for_path(pth)`
        @monitor = @file.monitor_directory(0)

        puts "Monitoring #{pth}..."
 
        @monitor.changed.connect() do |src,dest,evt|
          cb(src,dest,evt) if cb != nil

          if evt == GLib::FileMonitorEvent::CREATED
            self.created_cb(src) if @created_cb != nil
          end
        end
      end

      def created(cb:event_cb) :Monitor
        @created_cb = cb
        return self
      end

      def deleted(cb:event_cb) :Monitor
        @deleted_cb = cb
        return self
      end
    end
  end
end
