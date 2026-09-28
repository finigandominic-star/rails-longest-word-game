require "json"
require "open-uri"

class GamesController < ApplicationController
  def new
    @letters_array = ('a'..'z').to_a.sample(10)
  end

  def score
    @word = params[:answer].to_s.downcase.strip
    @letters = params[:letters].to_s.chars

    start_time = params[:start_time].to_i
    @time_elapsed = Time.now.to_i - start_time

    session[:total_score] ||= 0
    session[:game_count] ||= 0

    @result_message = word_score
  end

  def word_score
    if !valid_word_one(@word, @letters)
      return "Sorry, but #{@word} can't be built out of #{@letters.join(", ")}"
    elsif !valid_word_two
      return "Sorry, but #{@word} does not seem to be a valid English word..."
    else
      # Calculate the score and interpolate it correctly
      final_score = calculate_score(@word, @time_elapsed)
      session[:total_score] += final_score
      session[:game_count] += 1

      return "Congratulations! #{@word} is a valid word! Round Score: #{final_score} | Total Score: #{session[:total_score]} (Games played: #{session[:game_count]})"
    end
  end

  def valid_word_one(word, allowed_chars)
    Set.new(word.chars).subset?(Set.new(allowed_chars))
  end

  def valid_word_two
    url = "https://dictionary.lewagon.com/#{@word}"

    # FIXED: Added the comma between url and read_timeout: 2
    response_serialized = URI.open(url, read_timeout: 2).read
    response = JSON.parse(response_serialized)
    return response["found"]
  rescue OpenURI::HTTPError, Net::OpenTimeout
    return false # Safely returns false if the API is too slow or down
  end

  def calculate_score(word, time_elapsed)
    time_elapsed = 1 if time_elapsed < 1

    base_score = word.length * 10
    final_score = base_score - time_elapsed
    [final_score, 0].max
  end
end
