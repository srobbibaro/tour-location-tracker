class TourLocation < ActiveRecord::Base
  def self.valid?(tour_location)
    numeric?(tour_location[:latitude]) &&
    numeric?(tour_location[:longitude]) &&
    !tour_location[:name].blank?
  end

  private
  def self.numeric?(val)
    Float(val) != nil rescue false
  end
end
