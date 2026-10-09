class LearnersController < ApplicationController
  before_action :set_learner, only: %i[show edit update destroy]

  def index
    @learners = current_user.learners.includes(:latest_season_plan).order(created_at: :desc)
  end

  def show
    @season_plans = @learner.season_plans.order(created_at: :desc)
  end

  def new
    @learner = current_user.learners.build(focus_areas: Learner::AREAS)
  end

  def create
    @learner = current_user.learners.build(learner_params)
    if @learner.save
      redirect_to @learner
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @learner.update(learner_params)
      redirect_to @learner
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @learner.destroy
    redirect_to learners_path
  end

  private

  def set_learner
    @learner = current_user.learners.find(params[:id])
  end

  def learner_params
    params.require(:learner).permit(:first_name, :age, :interests, :season_needs, :available_offerings, focus_areas: [])
  end
end
