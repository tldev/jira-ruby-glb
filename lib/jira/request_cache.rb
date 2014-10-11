module JIRA

  class RequestCache

    def initialize(time_to_live)
      @time_to_live = time_to_live
      @hash_creator = Digest::MD5.new
    end

    def load(uri)
      key = cache_key(uri)
      cache_object = cache(uri)
      response = verify cache_object[key]

      if response == :expired
        cache_object.delete(key)
        file = cache_file(uri, 'w+')
        file.write(Marshal.dump(cache_object))
        file.close
        nil
      else
        response
      end
    end

    def save(uri, response)
      now = Time.now.to_i

      new_cache = cache(uri)
      new_cache[cache_key(uri)] = {
        'data' => response,
        'timestamp' => now
      }

      file = cache_file(uri, 'w+b')
      file.write(Marshal.dump(new_cache))
      file.close
    end


    private

    def verify(cache_value)
      now = Time.now.to_i
      #binding.pry
      if cache_value == nil
        return nil
      elsif cache_value['timestamp'] < (now - @time_to_live)
        :expired
      else
        cache_value['data']
      end
    end

    def cache(uri)
      if File.exists? cache_path(uri)
        file = cache_file(uri, 'r+b')
        cache_content = Marshal.restore(file.read())
        file.close
        cache_content
      else
        {}
      end
    end

    def cache_key(uri)
      return "key"
      #Marshal.dump(uri)
    end

    def cache_file(uri, mode)
      path = cache_path(uri)
      File.new(path, mode)
    end

    def cache_path(uri)
      dir = 'cache'
      
      unless Dir.exists? dir
        FileUtils.mkdir_p(dir)
      end
      
      @hash_creator.reset
      dir + '/' + @hash_creator.update(uri).to_s
    end
  end

end