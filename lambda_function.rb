require 'net/http'
require 'uri'
require 'json'
require 'addressable/uri'
require 'dotenv/load'
require 'aws-record'

class GoodEatsReviews # DynamoDB上に存在するテーブルを定義
  include Aws::Record
  string_attr :restaurant_id, hash_key: true
  string_attr :author_name, range_key: true
  string_attr :place_id
  integer_attr :rating
  string_attr :text
  string_attr :relative_time_description
end

def fetch_data(resource) # URIを引数として入力するとJSON形式でレスポンスが出力される汎用的な関数
  enc_str = Addressable::URI.encode(resource)
  uri = URI.parse(enc_str)
  json = Net::HTTP.get(uri)
  JSON.parse(json)
end

def search(small_area, genre_code)
  restaurants = []
  resource = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=#{ENV['RECRUIT_API_KEY']}&small_area=#{small_area}&order=4&genre=#{genre_code}&count=100&format=json"
  response = fetch_data(resource)
  results = response['results']
  hit_count = results['results_available']
  return if hit_count === 0
  shops = results['shop']
  shops.each do |shop|
    restaurants.push(shop)
  end
  if hit_count > 100
    total_pages = (hit_count / 100).to_i
    1...total_pages.times do |i|
      second_resource = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=#{ENV['RECRUIT_API_KEY']}&small_area=#{area}&order=4&genre=#{genre_code}&count=100&start=#{(i + 1) * 100 + 1}&format=json"
      second_response = fetch_data(second_resource)
      second_results = second_response['results']
      next if second_results['results_returned'] === "0"
      second_shops = second_results['shop']
      second_shops.each do |shop|
        restaurants.push(shop)
      end
    end
  end
  restaurants
end

def lambda_handler(event:, context:)
  # small_area = event['small_area']　# ホットペッパーAPIで定義されている小エリアコード
  # genre_code = event['genre'] # ホットペッパーAPIで定義されているジャンルコード

  matched_restaurants = []
  # restaurants = search(small_area, genre_code)
  restaurants = search('X150', 'G001')

  begin
    restaurants.each do |restaurant|
      reviews = GoodEatsReviews.scan(
        filter_expression: "contains(#B, :b)",
        expression_attribute_names: {"#B" => "restaurant_id"},
        expression_attribute_values: {":b" => restaurant['id']}
      )
      matched_restaurants.push(
        {
          detail: restaurant,
          reviews: reviews
        }
      )
    end
  rescue
    return {
      count: 0,
      restaurants: []
    }
  end
  # matched_restaurants.sort_by! {|restaurant| restaurant['reviews']}
  {
     count: matched_restaurants.count,
     restaurants: matched_restaurants
  }
end
