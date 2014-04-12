# @note The multimap gem was yanked, so we re-implement its functionality.
# @see https://github.com/josh/multimap
module MultiMail
  class Multimap
    def initialize
      @hash = {}
    end

    def [](key)
      @hash[key]
    end

    def []=(key, value)
      @hash[key] ||= []
      @hash[key] << value
    end

    def ==(other)
      if Multimap === other
        @hash == other.hash
      else
        @hash == other
      end
    end

    def size
      @hash.values.flatten.size
    end

    def each_pair
      @hash.each_pair do |key,values|
        values.each do |value|
          yield key, value
        end
      end
    end

    def merge(other)
      dup.update(other)
    end

    def update(other)
      if Multimap === other
        other.each_pair do |key,value|
          self[key] = value
        end
      else
        raise ArgumentError
      end
      self
    end

    def to_hash
      @hash.dup
    end

  protected

    def hash
      @hash
    end
  end
end
