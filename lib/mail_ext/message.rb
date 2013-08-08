module Mail
  class Message
    def tag(val = nil)
      default :tag, val
    end

    def tag=(val)
      header[:tag] = val
    end
  end
end
