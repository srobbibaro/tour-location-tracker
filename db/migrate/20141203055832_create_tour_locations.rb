class CreateTourLocations < ActiveRecord::Migration
  def change
    create_table(:tour_locations) do |t|
      t.float :longitude
      t.float :latitude
      t.string :name

      t.timestamps
    end

    add_reference :tour_locations, :user, index: true
  end
end
