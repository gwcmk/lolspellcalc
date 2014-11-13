  class SpellCalc

  require 'lol'
  client = Lol::Client.new "XXXXXXXXXXXXXXXX", {region: "na"}
  CHAMPS = client.static.champion.get(champData: 'spells')
  DAMAGE_SPELLS = Array.new
  DS_INFO = Array.new

  EXCEPTIONS = ["Consume", "CassiopeiaTwinFang", "VelkozW", "ViktorPowerTransfer", "PhosphorusBomb", "GnarE", "VolibearW", "VladimirSanguinePool", "SejuaniNorthernWinds", "Landslide", "XerathArcaneBarrage2", "NasusQ", "MissFortuneRicochetShot", "BraumQ", "RiftWalk", "EzrealMysticShot"]
  # Consume does damage to minions
  # CassiopeiaTwinFang, ViktorPowerTransfer, "EvelynnQ", "PhosphorusBomb", "GnarE", "MissFortuneRicochetShot", "BraumQ", "RiftWalk", "EzrealMysticShot" are missing its ratio in "vars"
  # VelkozW, "XerathArcaneBarrage2" do not have the correct cooldown in the the "cooldown" array
  # "VolibearW", "SejuaniNorthernWinds", "VladimirSanguinePool" have a health ratio
  # "Landslide", "Shatter" have an armor ratio
  # "NasusQ" has a link to @stacks...no way to know that

  # build DAMAGE_SPELLS
  CHAMPS.each do |champ|
  	champ.spells.each do |ability|
  		if ability["sanitizedTooltip"] =~ /deal\w{0,3} {{/ and !(EXCEPTIONS.include? ability["key"])
  			DAMAGE_SPELLS.push(ability)
  		end
  	end
  end

  # build DS_INFO
  DAMAGE_SPELLS.each do |ability|

  	if ability["maxrank"] == 3
  		ult = "yes"
  	else
  		ult = "no"
  	end

  	if ability["sanitizedTooltip"] =~ /deal\w{0,3} {{ e\d }}/
  		bd_index = ability["sanitizedTooltip"].match(/deal\w{0,5} {{ e\d }}/)[0].match(/\d/)[0].to_i # stores the index at which the base damage is stored
  		coeff_key = Array.new # an example of this would be "a1", so that the program can find the corresponding ratio in "vars"
  		coeff = Array.new # this is the numeric ratio
  		coeff_type = Array.new # this is the type of ratio, for example, "attackdamage"

      # These if statements determine whether or not the ability has multiple ratios
  		if ability["sanitizedTooltip"] =~ /deal\w{0,3} {{ e\d }} \(\+{{ a\d }}\) \(\+{{ a\d }}\)/
  			buffer = ability["sanitizedTooltip"].match(/deal\w{0,3} {{ e\d }} \(\+{{ a\d }}\) \(\+{{ a\d }}\)/)[0].split('+')
  			for i in 1..(buffer.length-1)
  				coeff_key.push(buffer[i].match(/\w\d/)[0])
  			end
  			coeff_key.each do |ck|
  				coeff.push(ability["vars"].find {|x| x["key"] == ck }["coeff"][0])
  				coeff_type.push(ability["vars"].find {|x| x["key"] == ck }["link"])
  			end
  			DS_INFO.push({ "key" => ability["key"], "base_damage" => ability["effect"][bd_index].last, "cooldown" => ability["cooldown"].last, "ratio" => coeff, "ratio_type" => coeff_type, "ult?" => ult })
  		elsif ability["sanitizedTooltip"] =~ /deal\w{0,3} {{ e\d }} \(\+{{ a\d }}\)/
  			coeff_key[0] = ability["sanitizedTooltip"].match(/deal\w{0,3} {{ e\d }} \(\+{{ a\d }}\)/)[0].match(/a\d/)[0]
  			coeff[0] = ability["vars"].find {|x| x["key"] == coeff_key[0] }["coeff"][0]
  			coeff_type[0] = ability["vars"].find {|x| x["key"] == coeff_key[0] }["link"]
  			DS_INFO.push({ "key" => ability["key"], "base_damage" => ability["effect"][bd_index].last, "cooldown" => ability["cooldown"].last, "ratio" => coeff, "ratio_type" => coeff_type, "ult?" => ult })
  		else
  			DS_INFO.push({ "key" => ability["key"], "base_damage" => ability["effect"][bd_index].last, "cooldown" => ability["cooldown"].last, "ratio" => 0, "ratio_type" => nil, "ult?" => ult })
  		end
  	else
  		DS_INFO.push({ "key" => ability["key"], "base_damage" => nil, "cooldown" => ability["cooldown"].last, "ratio" => nil, "ratio_type" => nil, "ult?" => ult })
  	end
  end

  def get_max(attack_damage, bonus_attack_damage, ability_power, ult, fight_time, cdr)
    max_damage = 0
    max_key = ""
    current = 0
    DS_INFO.each do |s|

      # checking if ultimates should be included
      if s["ult?"] == "yes" && ult == "No"
        next
      end

      # stores current calculation and compares to max
      current = get_damage(attack_damage, bonus_attack_damage, ability_power, ult, fight_time, cdr, s) 
      if current.nil? or s["base_damage"].nil?
        next
      elsif current > max_damage
        max_damage = current
        max_key = s["key"]
      end
    end

    return { "key" => max_key, "damage" => max_damage, "description" => DAMAGE_SPELLS.find {|x| x["key"] == max_key }["sanitizedDescription"] }
  end

  def get_damage(attack_damage, bonus_attack_damage, ability_power, ult, fight_time, cdr, spell)
    damage = spell["base_damage"]
    if spell["ratio_type"].nil?
      return damage
    else
      for i in 0..(spell["ratio_type"].length-1)
        rt = spell["ratio_type"][i]
        case rt
        when "attackdamage"
          damage += attack_damage * spell["ratio"][i]
        when "bonusattackdamage"
          damage += bonus_attack_damage * spell["ratio"][i]
        when "spelldamage"
          damage += ability_power * spell["ratio"][i]
        else
          damage += 0
        end
      end
    end

    # This calculates damage for scenarios where the spell can be used more than once
    if spell["cooldown"] > 1 && fight_time > 0
      damage = damage * ( fight_time / ( spell["cooldown"] * (1-(cdr*0.01)) ) ).floor
    end

    return damage
  end

end