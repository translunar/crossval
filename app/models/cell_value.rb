class CellValue
  attr_reader :masked

  def initialize(masked = false)
    @masked = masked
  end

  def masked?
    self.masked
  end

  def entry
    true
  end
end