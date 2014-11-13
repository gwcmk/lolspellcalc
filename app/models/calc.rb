class Calc < ActiveRecord::Base
	validates :attack_damage, numericality: {less_than_or_equal_to: 1500}
	validates :bonus_attack_damage, numericality: {less_than_or_equal_to: 1500}
	validates :ability_power, numericality: {less_than_or_equal_to: 1730}
	validates :ult, presence: true
	validates :cooldown_reduction, numericality: {less_than_or_equal_to: 40}
	validates :fight_time, presence: true
end
