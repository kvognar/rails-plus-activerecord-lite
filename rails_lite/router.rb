class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name
  
  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end
  
  def matches?(req)
    req.request_method.downcase.to_sym == @http_method &&
      (req.path =~ self.pattern) != nil
  end
  
  def run(req, res)
    match_data = @pattern.match(req.path)
    names_and_captures = match_data.names.zip(match_data.captures).flatten
    route_params = Hash[*names_and_captures]
    controller = controller_class.new(req, res, route_params)
    controller.send(self.action_name)
  end
end

class Router
  attr_reader :routes
  
  def initialize
    @routes = []
  end
  
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end
  
  def draw(&proc)
    self.instance_eval(&proc)
  end
  
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end
  
  def match(req)
    @routes.each do |route|
      return route if route.matches?(req)
    end
    nil
  end
  
  def run(req, res)
    route = match(req)
    if route.nil?
      res.status = 404
      res.body == "404'd!"
    else
      route.run(req, res)
    end
  end
  
end

    