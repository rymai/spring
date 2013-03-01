module Spring
  class ListenWatcher
    attr_reader :root_path, :files, :directories, :listener, :listener_options

    def self.available?
      require 'listen'
      true
    rescue LoadError
      false
    end

    def initialize(root_path, listener_options = {})
      @root_path        = File.realpath(root_path)
      @files            = []
      @directories      = []
      @stale            = false
      @listener_options = listener_options
    end

    def add_files(new_files)
      new_files = Array(new_files).select { |f| File.exist?(f) }

      files.concat new_files.map { |f| File.realpath(f) }
      files.uniq!
    end

    def add_directories(new_directories)
      directories.concat Array(new_directories).map { |d| File.realpath(d) }
    end

    def stale?
      @stale
    end

    def start
      setup unless @listener

      @listener.start(false)
    end

    def stop
      @listener.stop if @listener && @listener.adapter
    end

    def restart
      stop
      setup
      start
    end

    def watching?(file)
      files.include?(file) || file.start_with?(*directories)
    end

    def changed(modified, added, removed)
      if (modified + added + removed).any? { |f| watching? f }
        @stale = true
      end
    end

    private

    def setup
      require 'listen'
      @listener = Listen.to(root_path, listener_options).change(&method(:changed))
    end
  end
end
