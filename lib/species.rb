class Species
  def initialize abbrev
    @value = abbrev_to_value abbrev
  end

  attr_reader :value

  def abbrev_to_value a
    case a
    when "Hs":  return 1000
    when "Hsr": return 999
    when "Mm":  return 800
    when "Mmr": return 799
    when "Dm":  return 600
    when "Dmr": return 599
    when "Ce":  return 500
    when "Cer": return 499
    when "Sc":  return 300
    when "Scr": return 299
    when "At":  return 100
    when "Atr":  return 99
    end
  end

  def <=> rhs
    self.value <=> rhs.value
  end

end