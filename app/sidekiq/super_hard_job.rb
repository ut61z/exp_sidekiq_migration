class SuperHardJob
  # Sidekiq V6で作成されるWorker
  include Sidekiq::Worker

  def perform(*args)
    puts "Doing super hard work in a background job!"
  end
end
