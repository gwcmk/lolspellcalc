class CalcsController < ApplicationController
  
  def new
  	@calc = Calc.new
  end

  def create
  	require 'SpellCalc'
  	sc = SpellCalc.new
  	@calc = Calc.new(calc_params)
  	max_hash = sc.get_max(@calc.attack_damage, @calc.bonus_attack_damage, @calc.ability_power, @calc.ult, @calc.fight_time, @calc.cooldown_reduction)
  	@calc.key = max_hash["key"]
  	@calc.damage = max_hash["damage"]
  	@calc.description = max_hash["description"]
  	if @calc.save
  		redirect_to @calc
  	else
  		flash[:notice] = "One of your inputs was invalid"
  		render 'new'
  	end
  end

  def show
  	@calc = Calc.find(params[:id])
  end

  private
  def calc_params
    params.require(:calc).permit(:attack_damage, :bonus_attack_damage, :ability_power, :ult, :cooldown_reduction, :fight_time, :key, :damage, :description)
  end
end