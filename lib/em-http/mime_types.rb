module MIME
  class Types

    # Return the first found content-type for a value considered as an extension or the value itself
    def type_for_extension ext
      candidates = @extension_index[ext]
      candidates.empty? ? ext : candidates[0].content_type
    end

    class << self
      def type_for_extension ext
        @__types__.type_for_extension ext
      end
    end
  end
end