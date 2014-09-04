require_relative './params'
require_relative './session'
require_relative './helpers/controller_helper'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'

class ControllerBase
  extend ControllerHelper
  include ControllerHelper
  
  def self.new(*args)
    setup_methods
    super(*args)
  end
  
  attr_reader :req, :res, :params
  
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params)
    self.class.setup_methods
  end
  
  def already_built_response?
    @already_built_response ||= false
  end
  
  def redirect_to(url)
    raise "Cannot render or redirect more than once" if already_built_response?
    @res.status = 302
    @res.header['location'] = url
    session.store_session(@res)
    @already_built_response = true
  end
  
  def render_content(content, type)
    raise "Cannot render or redirect more than once" if already_built_response?
    @res.content_type = type
    @res.body = content
    session.store_session(@res)
    @already_built_response = true
  end
  
  def render(template_name)
    file = File.read(
      "views/#{self.class.name.underscore}/#{template_name}.html.erb")
    view = ERB.new(file).result(binding)
    render_content(view, "text/html")
  end
  
  def session
    @session ||= Session.new(@req)
  end
  
  
  
end