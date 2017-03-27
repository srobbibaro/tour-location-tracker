require "rails_helper"

RSpec.describe TourLocationsController, :type => :controller do
  describe "Authenticated user" do
    let (:user) {FactoryGirl.create(:user)}

    before do
      sign_in :user, user
    end

    describe "Get #index" do
      it "responds with success" do
        get :index

        expect(response).to have_http_status(200)
      end
    end

    describe "Get locations" do
      it "returns locations for user" do
        FactoryGirl.create_list(:tour_location, 3, user_id: user.id)
        other_user = FactoryGirl.create(:user, email: 'otherpomuser@example.com')
        FactoryGirl.create(:tour_location, user_id: other_user.id)
        get :locations

        result = JSON.parse(response.body)
        expect(result.length).to be(3)
        expect(response).to have_http_status(200)
      end
    end

    describe "Remove location" do
      describe "with no saved locations" do
        it "returns unsuccessful status" do
          post :remove_location

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end
      end

      describe "with saved locations" do
        it "returns unsuccessful status when id doesn't match" do
          a = FactoryGirl.create(:tour_location, user_id: user.id)
          post :remove_location, {id: a.id + 1}

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end

        it "returns unsuccessful status when id doesn't match one for user" do
          other_user = FactoryGirl.create(:user, email: 'otherpomuser@example.com')
          a = FactoryGirl.create(:tour_location, user_id: other_user.id)

          expect(TourLocation.first.id).to eq(a.id)

          post :remove_location, {id: a.id}

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
          expect(TourLocation.first.id).to eq(a.id)
        end

        it "returns successful status when id does match" do
          a = FactoryGirl.create(:tour_location, user_id: user.id)

          expect(TourLocation.first.id).to eq(a.id)

          post :remove_location, {id: a.id}

          expect(JSON.parse(response.body)['result']).to be(true)
          expect(response).to have_http_status(200)
          expect(TourLocation.count).to eq(0)
        end
      end
    end

    describe "Create location" do
      describe "Unsuccessful save" do
        it "returns unsuccessful status with invalid params" do
          expect{ post(:add_location, {}) }.to raise_error ActionController::ParameterMissing
        end

        it "returns unsuccessful status when new location matches saved name" do
          params = {
            location: {
              name: 'My Location',
              longitude: 0,
              latitude: 0,
            }
          }
          FactoryGirl.create(:tour_location, user_id: user.id)
          post :add_location, params

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end
      end

      describe "Successful save" do
        before do
          @params = {
            location: {
              name: 'Test Location',
              longitude: 0,
              latitude: 0,
            }
          }
        end

        it "returns successful status when new location does not match saved name" do
          FactoryGirl.create(:tour_location, user_id: user.id)
          post :add_location, @params

          result = JSON.parse(response.body)
          expect(result['name']).to eq('Test Location')
          expect(JSON.parse(response.body)['result']).to be(true)
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
