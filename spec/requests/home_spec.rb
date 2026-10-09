require "rails_helper"

RSpec.describe "Home", type: :request do
  it "shows the pitch and the fictional example to visitors" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Bake a loaf from start to finish", "A gap is a to-do for the community", "https://virtuesgarden.com")
    expect(response.body).to include("Try it free")
  end

  it "sends a signed-in guardian to their learners" do
    sign_in_as(create(:user))
    get root_path
    expect(response.body).to include("Go to my learners")
  end
end
