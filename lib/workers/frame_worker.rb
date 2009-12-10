module Workers
  # This is the worker that is responsible for running asnynchronous analysis jobs.
  class FrameWorker < Workling::Base
    def run options = {}
      opts = options

      experiment = Experiment.find(opts[:experiment_id])

      raise(ArgumentError, "Experiment ID not found") if experiment.nil?
      raise(ArgumentError, "Experiment #{opts[:experiment_id]} has already been run") if experiment.has_been_run?

      logger.info("Running experiment on id #{opts[:experiment_id]}")

      experiment.run

      logger.info("DONE running experiment on id #{opts[:experiment_id]}")
    end
  end
end