require 'webrick'
require_relative './rails_lite/controller_base'
require_relative './rails_lite/router'
require_relative './active_record_lite/sql_object'


# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

# $cats = [
#   { id: 1, name: "Curie" },
#   { id: 2, name: "Markov" }
# ]
#
# $statuses = [
#   { id: 1, cat_id: 1, text: "Curie loves string!" },
#   { id: 2, cat_id: 2, text: "Markov is mighty!" },
#   { id: 3, cat_id: 1, text: "Curie is cool!" }
# ]


class Cat < SQLObject
  belongs_to :human, foreign_key: :owner_id
  finalize!
end

class Human < SQLObject
  self.table_name = 'humans'
  
  has_many :cats, foreign_key: :owner_id
  belongs_to :house
  finalize!
end

class House < SQLObject
  has_many :humans
  finalize!
end

# class StatusesController < ControllerBase
#   def index
#     statuses = $statuses.select do |s|
#       s[:cat_id] == Integer(params[:cat_id])
#     end
#
#     render_content(statuses.to_s, "text/text")
#   end
# end

class CatsController < ControllerBase
  def index
    @cats = Cat.all
    render :index
    puts self.methods - 5.methods
    # render_content(@cats.to_s, "text/text")
  end
  
  def new
    @cat = 
    render :new
  end
  
  def show
    @cat = Cat.find(Integer(params[:cat_id]))
    
    render :show
  end
  
  def create
    print params
    @cat = Cat.new(params[:cat])
    @cat.save
    redirect_to cats_path
    # render_content(params, "text/text")
  end
  
  
end

router = Router.new
router.draw do
  get Regexp.new("^/cats/?$"), CatsController, :index
  get Regexp.new("^/cats/new/?$"), CatsController, :new
  get Regexp.new("^/cats/(?<cat_id>\\d+)$"), CatsController, :show
  post Regexp.new("^/cats/?$"), CatsController, :create
  
  # get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  route = router.run(req, res)
end

trap('INT') { server.shutdown }
server.start
