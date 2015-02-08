require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'asdfzxcvqwer' 

helpers do
CARD_VALUE = {"A" => 1, "1" => 1, "2" => 2, "3" => 3, "4" => 4,
                 "5" => 5, "6" => 6, "7" => 7, "8" => 8, "9" => 9,
                 "10" => 10, "J" => 10, "Q" => 10, "K" => 10} 
SUITS = {"H" => "hearts", "C" => "clubs", "D" => "diamonds", "S" => "spades"}
VALUE = {"2" => "2", "3" => "3", "4" => "4", "5" => "5", "6" => "6", "7" => "7", "8" => "8", 
            "9" => "9", "10" => "10", "J" => "jack", "Q" => "queen", "K" => "king", "A" => "ace"}
BLACKJACK = 21
DEALER_MIN_HIT = 17

  def calc_hand(hand)
    total = 0

    hand.each do |card|
      total += CARD_VALUE[card[0]]
    end

    total = ace_value(hand, total)
  end

  def ace_value(hand, total)
    hand.each do |card|
      if card[0].include?('A')
        if total + 10 <= BLACKJACK
          total += 10
        end
      end
    end
    total
  end

  def draw_card(card)
    "<img src='/images/cards/#{SUITS[card[1]]}_#{VALUE[card[0]]}.jpg' class='card_image'>"

  end

  def winner!(msg)
    @success = "Congratulation #{session[:player_name]}. #{msg}"
    @show_hit_or_stay_button = false
    @play_again = true
  end

  def loser!(msg)
    @error = "Sorry #{session[:player_name]}. #{msg}"
    @show_hit_or_stay_button = false
    @play_again = true
  end

  def tie!(msg)
    @success = "It's a tie. #{msg}"
    @show_hit_or_stay_button = false
    @play_again = true
  end

end

before do
  @show_hit_or_stay_button = true
  @play_again = false
end

get '/' do
  if params[:player_name]
    redirect '/game'
  else
    redirect '/new_game'
  end
end

get '/new_game' do
  erb :new_game
end

post '/new_game' do
  if params[:player_name].empty?
    @error = "A name must be entered."
    halt erb :new_game
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  if session[:player_name]
    session[:turn] = session[:player_name]
    session[:deck] = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'K', 'Q', 'J', 'A'].product(['H', 'S', 'D', 'C']).shuffle!
    session[:player_hand] = []
    session[:dealer_hand] = []
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop

    if calc_hand(session[:player_hand]) == BLACKJACK
      winner!("BLACKJACK!")
    end

    erb :game
  else
    redirect '/new_game'
  end
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop

  player_total = calc_hand(session[:player_hand])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} has hit Blackjack!")
  elsif player_total > BLACKJACK
    loser!("#{session[:player_name]} has busted with #{player_total}.")
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} chose to stay."
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_button = false
  session[:turn] = "dealer"

  dealer_total = calc_hand(session[:dealer_hand])
  if dealer_total == BLACKJACK
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("Dealer has busted with #{dealer_total}. #{session[:player_name]} wins!")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  @show_hit_or_stay_button = false
  session[:dealer_hand] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_button =false
  player_total = calc_hand(session[:player_hand])
  dealer_total = calc_hand(session[:dealer_hand])
  if player_total > dealer_total
    winner!("#{session[:player_name]} has #{player_total} compared to the dealer's #{dealer_total}.")
  elsif player_total < dealer_total
    loser!("Dealer has #{dealer_total} compared to #{session[:player_name]}'s #{player_total}.")
  else
    tie!("#{session[:player_name]} and dealer both have #{player_total}")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end