class Array
#  def sum
#    inject(0) { |sum,x| sum + x}
#  end
  def mean
    (size > 0) ? sum.to_f / size : 0
  end
end