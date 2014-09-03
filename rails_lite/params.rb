class Params
  
  def initialize(req, route_params = {})
    @params = route_params
    
    parse_www_encoded_form(req.query_string)
    parse_www_encoded_form(req.body) if req.body
    
  end
  
  def [](key)
    @params[key.to_s] || (raise AttributeNotFoundError)
  end
  
  def to_s
    @params.to_json.to_s
  end
  
  class AttributeNotFoundError < ArgumentError; end;
  
  private 
  
  def parse_www_encoded_form(www_encoded_form)
    return if www_encoded_form.nil?
    URI::decode_www_form(www_encoded_form).each do|key, val|
      keys = parse_key(key)
      if keys.count == 1
        @params[key] == val
      else
        make_nested_hash(keys, val)
      end
    end
  end
  
  def make_nested_hash(keys, val)
    sub_hash = @params[keys.first] ||= {}
    keys[1...-1].each do |key|
      sub_hash = sub_hash[key] ||= {}
    end
    
    sub_hash[keys.last] = val
  end
  
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end
  
end