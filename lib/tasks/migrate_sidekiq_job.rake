namespace :sidekiq do
  desc 'Migrate Sidekiq jobs from one Redis to another'
  task migrate_jobs: :environment do
    require 'sidekiq'
    require 'sidekiq/api'

    # 元のRedisのURLを環境変数にセット
    ENV['REDIS_URL'] = 'redis://old_redis_url'

    # Sidekiqのスケジュールされたジョブを元のRedisから取得して表示
    Sidekiq::ScheduledSet.new.each do |job|
      puts job.klass, job.args, job.at
    end

    # それらを変数に格納しておく
    ss = Sidekiq::ScheduledSet.new

    # 新RedisのURLを環境変数にセット
    ENV['REDIS_URL'] = 'redis://new_redis_url'

    # Sidekiqのスケジュールされたジョブを新しいRedisに移動
    ss.each do |job|
      job.reschedule(job.at)
    end
  end
end
