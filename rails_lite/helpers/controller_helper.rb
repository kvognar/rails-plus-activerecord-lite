require 'active_support/inflector'

module ControllerHelper
  
  def link_to(anchor, url)
    <<-HTML
    <a HREF="#{url}">#{anchor}</a>
    HTML
  end
  
  def setup_methods
    word_root = self.to_s[0...-("Controller".length)].downcase
    
    define_method("#{word_root}_path") do
      "/#{word_root}"
    end
  
    define_method("#{word_root.singularize}_path") do |id|
      "/#{word_root}/#{id}"
    end
    
    define_method("new_#{word_root.singularize}_path") do
      "/#{word_root}/new"
    end
  end

  
end