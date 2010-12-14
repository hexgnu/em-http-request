require 'tempfile'
class Multipart
  EOL = "\r\n"

  def build_stream(params)
    header = "Content-type: multipart/form-data; boundary=#{boundary}"
    b = "--#{boundary}"
    
    @stream = Tempfile.new("em-http-request-stream#{rand(1000)}")
    @stream.binmode
    @stream.write(header + EOL + b + EOL)
    
    if params.is_a? Hash
      x = flatten_params(params)
    else
      x = params
    end

    last_index = x.length - 1
    x.each_with_index do |a, index|
      k, v = * a
      if v.respond_to?(:read) && v.respond_to?(:path)
        create_file_field(@stream, k, v)
      else
        create_regular_field(@stream, k, v)
      end
      @stream.write(EOL + b)
      @stream.write(EOL) unless last_index == index
    end
    @stream.write('--')
    @stream.write(EOL)
    @stream.seek(0)
    @stream
  end

  def create_regular_field(s, k, v)
    s.write("Content-Disposition: form-data; name=\"#{k}\"")
    s.write(EOL)
    s.write(EOL)
    s.write(v)
  end

  def create_file_field(s, k, v)
    begin
      s.write("Content-Disposition: form-data;")
      s.write(" name=\"#{k}\";") unless (k.nil? || k=='')
      s.write(" filename=\"#{v.respond_to?(:original_filename) ? v.original_filename : File.basename(v.path)}\"#{EOL}")
      s.write("Content-Type: #{v.respond_to?(:content_type) ? v.content_type : mime_for(v.path)}#{EOL}")
      s.write(EOL)
      while data = v.read(8124)
        s.write(data)
      end
    ensure
      v.close
    end
  end

  def mime_for(path)
    mime = MIME::Types.type_for path
    mime.empty? ? 'text/plain' : mime[0].content_type
  end

  # for Multipart do not escape the keys
  def handle_key key
    key
  end
  
  def boundary
    @boundary ||= rand(1_000_000).to_s
  end

  def headers
    super.merge({'Content-Type' => %Q{multipart/form-data; boundary=--#{boundary}}})
  end
  
  def flatten_params(params, parent_key = nil)
    result = []
    params.each do |key, value|
      calculated_key = parent_key ? "#{parent_key}[#{handle_key(key)}]" : handle_key(key)
      if value.is_a? Hash
        result += flatten_params(value, calculated_key)
      elsif value.is_a? Array
        result += flatten_params_array(value, calculated_key)
      else
        result << [calculated_key, value]
      end
    end
    result
  end
  
   def flatten_params_array value, calculated_key
      result = []
      value.each do |elem|
        if elem.is_a? Hash
          result +=  flatten_params(elem, calculated_key)
        elsif elem.is_a? Array
          result += flatten_params_array(elem, calculated_key)
        else
          result << ["#{calculated_key}[]", elem]
        end
      end
      result
    end

  def close
    @stream.close
  end
end