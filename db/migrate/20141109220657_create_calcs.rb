class CreateCalcs < ActiveRecord::Migration
  def change
    create_table :calcs do |t|
	  t.decimal :attack_damage
      t.decimal :bonus_attack_damage
      t.decimal :ability_power
      t.string :ult
      t.decimal :cooldown_reduction
      t.decimal :fight_time
      t.string :key
      t.decimal :damage
      t.string :description
      t.timestamps
    end
  end
end
