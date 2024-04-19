class HardJob
  include Sidekiq::Job

  def perform(*args)
    puts "Doing hard work in a background job!"
  end
end
