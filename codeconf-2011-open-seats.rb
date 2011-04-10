require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-migrations'
require 'dm-timestamps'
require 'logger'
require 'haml'
require 'sinatra/content_for2'
require 'json/pure'

configure :development do
  DataMapper::Logger.new('tmp/seatr-debug.log', :debug)
  DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/development.db")
end

configure :production do
  # Configure stuff here you'll want to
  # only be run at Heroku at boot

  # TIP:  You can get you database information
  #       from ENV['DATABASE_URI'] (see /env route below)
end

class Seat
  include DataMapper::Resource

  property :id, Serial
  property :loc, String
  property :twitter, String
  property :taken, Boolean, :default => true
  property :created, DateTime
  property :updated, DateTime

end

DataMapper.finalize
#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

#=end

get "/" do
  @seats = Seat.all
  @title = "Open Seats"
  if @seats.count == 0 then
    redirect '/create'
  end
  haml :home
end

get "/create" do
  rows = 17
  cols = 21

  for i in 0..rows
    for j in 0..cols

      s = Seat.new(
        :loc => "seat-#{i}-#{j}",
        :taken => true,
        :created => Time.now
      )

      s.save

    end
  end

  redirect '/'

end

get "/seats.json" do
  @seats = Seat.all(:order => [ :loc.asc ])
  data = {}

  currentRow = nil
  temp = nil
  @seats.each do |seat|
=begin
    if seat.row != currentRow then
      data[seat.row] = {}
      currentRow = seat.row
    end
=end
    data[seat.loc] = {}

    #data[seat.row][seat.col] = seat.taken ? (seat.twitter ? seat.twitter : "x") : nil
    data[seat.loc]["taken"] = seat.taken
    data[seat.loc]["twitter"] = seat.twitter

  end

  content_type :json
  data.to_json
end

get "/update/:loc/mark/:taken[/]?" do
  seat = Seat.first(:loc => params[:loc])
  #"#{seat.inspect}"
  seat.update(:taken => (params[:taken] != 'open'), :twitter => params[:taken], :updated => Time.now)
  if seat.save then
    #redirect '/'
    "#{seat.taken}"
  end
end
