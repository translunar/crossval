#require 'array_ext'

module Statistics
  class ROC

    def initialize options = {}
      if options.has_key?(:known_correct) && options.has_key?(:guess_to_priority_hash)
        pos_neg = Statistics::positives_and_negatives(options[:known_correct], options[:guess_to_priority_hash], options)
        @true_positives  = pos_neg[:true_positives].size
        @false_positives = pos_neg[:false_positives].size
        @true_negatives  = pos_neg[:true_negatives].size
        @false_negatives = pos_neg[:false_negatives].size

        @area_under_curve = ROC.calculate_area_under_curve(options[:known_correct], Statistics::sort_rows_by_distance(options[:guess_to_priority_hash]))
      else
        STDERR.puts("Warning: ROC created with sizes only")
        @true_positives = options[:num_true_positives] || options[:tp]
        @false_positives = options[:num_false_positives] || options[:fp]
        @true_negatives = options[:true_negatives] || options[:tn]
        @false_negatives = options[:false_negatives] || options[:fn]
      end
    end

    attr_reader :true_positives, :false_positives, :true_negatives, :false_negatives, :area_under_curve
    alias :tp :true_positives
    alias :fp :false_positives
    alias :tn :true_negatives
    alias :fn :false_negatives
    alias :auc :area_under_curve

    # This code is based upon Martin's rocker AUC code (which is in Python).
    # Hopefully the translation is correct.
    # There is a TODO on his also:
    # TODO: Fix so that missed ones etc are reported, as in Kris's webtool.
    # I'm not sure if this should still be there.
    # It's really ugly code. Not my favorite.
    def self.calculate_area_under_curve known_correct, candidates, options = {}
      t = [0] # true
      f = [0] # false
      candidates.each do |item|
        if known_correct.include?(item)
          t << t.last + 1
          f << f.last
        else
          t << t.last
          f << f.last + 1
        end
      end

      tpl = []
      fpl = []
      last_f = 0
      t.each_index do |i|
        if f[i] > last_f
          tpl << t[i]
          fpl << f[i]
          last_f = f[i]
        end
      end

      tprl = tpl.collect { |x| x / tpl.last.to_f }
      fprl = fpl.collect { |y| y / fpl.last.to_f }

      if options.has_key?(:cut_off)
        tprl[0...options[:cut_off]].sum / options[:cut_off].to_f
      elsif options.has_key?(:measure)
        tprl.collect{ |x| x * options[:measure].to_f }.sum
      elsif options.has_key?(:fpr_cut_off)
        hits = []
        fprl.each_index do |i|
          hits << tprl[i] if fprl[i] < options[:fpr_cut_off]
        end
        raise(ArgumentError, "Martin needs to explain his code.")
        hits.sum / 13745.0 # This is from Martin's code and I think it makes no sense.
      else
        tprl.sum / tprl.size.to_f
      end
    end

    def positives
      @positives ||= @true_positives + @false_positives
    end

    def negatives
      @negatives ||= @true_negatives + @false_negatives
    end

    def true_positive_rate
      @true_positive_rate ||= @true_positives / positives.to_f
    end
    alias :tpr :true_positive_rate
    alias :sensitivity :true_positive_rate
    alias :recall :true_positive_rate
    alias :hit_rate :true_positive_rate

    def false_positive_rate
      @false_positive_rate ||= @false_positives / negatives.to_f
    end
    alias :fpr :false_positive_rate
    alias :false_alarm_rate :false_positive_rate
    alias :fall_out :false_positive_rate

    def accuracy
      @accuracy ||= (@true_positives + @true_negatives) / (positives + negatives).to_f
    end
    alias :acc :accuracy

    def true_negative_rate
      @specificity ||= @true_negatives / negatives.to_f
    end
    alias :tnr :true_negative_rate
    alias :specificity :true_negative_rate

    def precision
      @precision ||= @true_positives / (@true_positives + @false_positives).to_f
    end
    alias :positive_predictive_value :precision
    alias :ppv :precision

    def negative_predictive_value
      @negative_predictive_value ||= @true_negatives / (@true_negatives + @false_negatives).to_f
    end
    alias :npv :negative_predictive_value

    def false_discovery_rate
      @false_discovery_rate ||= @false_positives / (@false_positives + @true_positives).to_f
    end
    alias :fdr :false_discovery_rate

    def matthews_correlation_coefficient
      @matthews_correlation_coefficient ||= mcc_numerator / mcc_denominator
    end
    alias :mcc :matthews_correlation_coefficient
    alias :matthews :matthews_correlation_coefficient

  protected
    def mcc_numerator
      @mcc_numerator ||= (@true_positives * @true_negatives - @false_positives * @false_negatives)
    end

    def mcc_denominator
      @mcc_denominator ||= Math.sqrt(mcc_denominator_inside_sqrt.to_f)
    end

    def mcc_denominator_inside_sqrt
      @mcc_denominator_inside_sqrt ||= positives*negatives*(@true_positives+@false_negatives)*(@true_negatives+@false_positives)
    end

  end

  # Given a hash from row to distance, return the rows in sorted order (least to most likely)
  def self.sort_rows_by_distance(row_to_distance)
    row_to_distance.sort { |b,a| a[1] <=> b[1] }.collect { |x| x.first }
  end


  # Returns lists of positives (true, false) and negatives (true, false) as
  # a hash.
  # Arguments:
  # * known_correct: a list of keys which are known to be true.
  # * guess_to_priority: hash from key to a distance metric of some sort.
  #
  # The distance metric should be normalized to between 0 (false) and 1 (true),
  # and represents the prediction (whether we think it's true or false).
  #
  # You can also set a :threshold in options, which is 0 by default. Anything
  # greater than :threshold will be counted as predicted, and anything less
  # than or equal to it will be counted as not predicted.
  #
  # Returned hash shall have keys :true_positives, :true_negatives, :false_positives,
  # and :false_negatives.
  def self.positives_and_negatives(known_correct, guess_to_priority, options = {})
    opts = {
      :threshold => 0
    }.merge options

    tp = [] # true positives
    fp = [] # false pos
    tn = [] # true neg
    fn = [] # false neg

    guess_to_priority.each_pair do |guess, priority|
      if priority > opts[:threshold]
        if known_correct.include?(guess)
          tp << guess
        else
          fp << guess
        end
      else
        if known_correct.include?(guess)
          fn << guess
        else
          tn << guess
        end
      end
    end

    { :true_positives  => tp,
      :true_negatives  => tn,
      :false_positives => fp,
      :false_negatives => fn }
  end

end