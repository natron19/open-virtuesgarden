require "rails_helper"

RSpec.describe "Learners", type: :request do
  let(:user)    { create(:user) }
  let(:other)   { create(:user) }
  let(:learner) { create(:learner, user: user) }

  let(:valid_params) do
    { learner: { first_name: "Tobias", age: "11", interests: "Builds marble runs and reads about volcanoes.",
                 season_needs: "Sticking with a hard problem, and time with adults outside the family.",
                 available_offerings: "Bike repair Saturdays (ages 10-16)", focus_areas: [ "", "academics", "service" ] } }
  end

  context "when not signed in" do
    it "redirects every page to sign in" do
      get learners_path
      expect(response).to redirect_to(sign_in_path)
      get dashboard_path
      expect(response).to redirect_to(sign_in_path)
      post learners_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when signed in" do
    before { sign_in_as(user) }

    it "shows the dashboard as My learners with only the user's own learners" do
      create(:learner, user: user, first_name: "Juniper")
      create(:learner, user: other, first_name: "Someoneelse")
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My learners", "Juniper")
      expect(response.body).not_to include("Someoneelse")
    end

    it "shows the latest season's summary on the dashboard" do
      create(:season_plan, :completed, learner: learner)
      get learners_path
      expect(response.body).to include("2 aims, 1 matched, 1 gap")
    end

    it "shows an empty state with no learners" do
      get learners_path
      expect(response.body).to include("Add your first learner")
    end

    it "renders the new form with the labels the UI journey fills, all five areas ticked" do
      get new_learner_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("First name", "Age", "Interests", "What this season needs",
                                       "Offerings you can reach", "Areas to focus on", "Practical skill")
      expect(response.body.scan(/type="checkbox"[^>]*checked="checked"/).size).to eq(5)
    end

    it "creates a learner with the ticked areas and redirects to it" do
      expect { post learners_path, params: valid_params }.to change(user.learners, :count).by(1)
      learner = Learner.last
      expect(learner.focus_areas).to eq(%w[academics service])
      expect(response).to redirect_to(learner_path(learner))
    end

    it "re-renders the form with 422 on invalid input" do
      expect {
        post learners_path, params: { learner: valid_params[:learner].merge(first_name: "Tobias Okafor", focus_areas: [ "" ]) }
      }.not_to change(Learner, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("first name only", "needs at least one area")
    end

    it "shows the learner with the Propose a season button" do
      get learner_path(learner)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(learner.first_name, "Propose a season", "Saturday bread class")
    end

    it "updates a learner" do
      patch learner_path(learner), params: { learner: { age: 10 } }
      expect(response).to redirect_to(learner_path(learner))
      expect(learner.reload.age).to eq(10)
    end

    it "rejects an invalid update with 422" do
      patch learner_path(learner), params: { learner: { age: 30 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "deletes a learner" do
      learner
      expect { delete learner_path(learner) }.to change(Learner, :count).by(-1)
      expect(response).to redirect_to(learners_path)
    end
  end

  # open-base's ApplicationController answers RecordNotFound with a redirect to root and an alert.
  context "when signed in as a different user" do
    before { sign_in_as(other) }

    it "cannot see, edit, update, or delete the learner" do
      get learner_path(learner)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("That record could not be found.")
      get edit_learner_path(learner)
      expect(response).to redirect_to(root_path)
      patch learner_path(learner), params: { learner: { first_name: "Hijacked" } }
      expect(response).to redirect_to(root_path)
      expect { delete learner_path(learner) }.not_to change(Learner, :count)
      expect(response).to redirect_to(root_path)
      expect(learner.reload.first_name).not_to eq("Hijacked")
    end
  end
end
